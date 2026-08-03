<?php
/*
    Plugin Name: WooCommerce CredibanCo
    Plugin URI:
    Description: Online payment with Credibanco.
    Version: 1.1.3
    Author: CredibanCo
    Text Domain: wc-credibanco-text-domain
    Domain Path: /lang
 */

ini_set('precision', 14);
ini_set('serialize_precision', 14);

if (!defined('ABSPATH')) exit;
require_once(ABSPATH . 'wp-admin/includes/plugin.php');
require_once(__DIR__ . '/include.php');

add_filter('plugin_row_meta', 'credibanco_register_plugin_links', 10, 2);
function credibanco_register_plugin_links($links, $file)
{
    $base = plugin_basename(__FILE__);
    if ($file == $base) {
        $links[] = '<a href="admin.php?page=wc-settings&tab=checkout&section=credibanco">' . __('Settings', 'woocommerce') . '</a>';
    }
    return $links;
}


add_action('plugins_loaded', 'wc_credibanco', 0);
function wc_credibanco()
{

    load_plugin_textdomain('wc-credibanco-text-domain', false, dirname(plugin_basename(__FILE__)) . '/lang');

    if (!class_exists('WC_Payment_Gateway'))
        return;
    if (class_exists('WC_RBSPayment_credibanco'))
        return;

    class WC_RBSPayment_credibanco extends WC_Payment_Gateway
    {

        public $icon_path;
        public $currency_codes = array(
            'USD' => '840',
            'UAH' => '980',
            'RUB' => '643',
            'RON' => '946',
            'KZT' => '398',
            'KGS' => '417',
            'JPY' => '392',
            'GBR' => '826',
            'EUR' => '978',
            'CNY' => '156',
            'BYR' => '974',
            'BYN' => '933'
        );

        public function __construct()
        {

            $this->id = 'credibanco';
            $this->icon_path = $icon_path = is_file(__DIR__ . DIRECTORY_SEPARATOR) ? plugin_dir_url(__FILE__) . 'logo.png' : null;

            $this->method_title = "CredibanCo";
            $this->method_description = "<img height='22' style='vertical-align:middle;' src=" . $icon_path . " / >&nbsp;" . __('Online payment with Credibanco.', 'wc-credibanco-text-domain');

            // Load the settings
            $this->init_form_fields();
            $this->init_settings();

            // Endpoints
            $this->prod_url = RBS_CREDIBANCO_PROD_URL;
            $this->test_url = RBS_CREDIBANCO_TEST_URL;
            $this->logging = RBS_CREDIBANCO_ENABLE_LOGGING;

//            $this->fiscale_options = ENABLE_FISCALE_OPTIONS;

            // Define user set variables
            $this->title = $this->get_option('title');
            $this->merchant = $this->get_option('merchant');
            $this->password = $this->get_option('password');
            $this->test_mode = $this->get_option('test_mode');
            $this->stage_mode = $this->get_option('stage_mode');
            $this->description = $this->get_option('description');
            $this->order_status = $this->get_option('order_status');
            $this->icon = $icon_path;

//            $this->installments = $this->get_option('installments');

            $this->send_order = $this->get_option('send_order');
            $this->tax_system = $this->get_option('tax_system');
            $this->tax_type = $this->get_option('tax_type');

            $this->success_url = $this->get_option('success_url');
            $this->fail_url = $this->get_option('fail_url');
//            $this->ffd_version = $this->get_option('ffd_version');
            $this->ffd_paymentMethodType = $this->get_option('ffd_paymentMethodType');
            $this->ffd_paymentObjectType = $this->get_option('ffd_paymentObjectType');
            $this->ffd_paymentObjectType_delivery = $this->get_option('ffd_paymentMethodType_delivery');

            $this->pData = get_plugin_data(__FILE__);
            $this->measurement_name = RBS_CREDIBANCO_MEASUREMENT_NAME;

            // Actions
            add_action('valid-rbspayment-standard-ipn-reques', array($this, 'successful_request'));
            add_action('woocommerce_receipt_' . $this->id, array($this, 'receipt_page'));

            // Save options
            add_action('woocommerce_update_options_payment_gateways_' . $this->id, array($this, 'process_admin_options'));

            if (!$this->is_valid_for_use()) {
                $this->enabled = false;
            }

            $this->callback();
        }

        public function process_admin_options()
        {
            $this->rbs_logger("Options Updated [" . $this->id . "]: \n" . print_r($_POST, true));

            if ($this->test_mode == 'yes') {
                $action_adr = $this->test_url;
            } else {
                $action_adr = $this->prod_url;
            }
            $gate_url = str_replace("payment/rest", "mportal/mvc/public/merchant/update", $action_adr);
            $gate_url .= substr($this->merchant, 0, -4); // we guess username = login w/o "-api"

            $callback_addresses_string = get_option('siteurl') . "/?wc-api=WC_RBSPayment_credibanco&credibanco=callback"; //todo
            $response = $this->updateRBSCallback($this->merchant, $this->password, $gate_url, $callback_addresses_string);

            $this->rbs_logger("[callback_addresses_string]: " . $callback_addresses_string);
            $this->rbs_logger("[RESPONSE]: " . $response);

            parent::process_admin_options();
        }

        public function updateRBSCallback($login, $password, $gate_url, $callback_addresses_string)
        {
            $headers = array(
                'Content-Type:application/json',
                'Authorization: Basic ' . base64_encode($login . ":" . $password)
            );
            $data['callbacks_enabled'] = true;
            $data['callback_addresses'] = $callback_addresses_string;
            $data['callback_operations'] = "deposited,approved,declinedByTimeout";

            $response = $this->_sendData(json_encode($data), $gate_url, $headers);
            return $response;

        }

        public function _sendData($data, $action_address, $headers = array())
        {

            $ch = curl_init();
            curl_setopt_array($ch, array(
                CURLOPT_HTTPHEADER => $headers,
                CURLOPT_VERBOSE => true,
                CURLOPT_SSL_VERIFYHOST => false,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_URL => $action_address,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => $data,
//                CURLOPT_ENCODING, "gzip",
//                CURLOPT_ENCODING, '',
            ));
            $response = curl_exec($ch);
            curl_close($ch);

            if (RBS_CREDIBANCO_ENABLE_LOGGING === true) {
                $this->rbs_logger("REQUEST: " . $action_address . ": \nDATA: " . print_r($data, true) . "\nRESPONSE: " . $response);
            }

            return $response;
        }


        public function callback()
        {
//            print_r($_GET);die;
            if (isset($_GET['credibanco'])) {

                $action = $_GET['credibanco'];

                if ($this->test_mode == 'yes') {
                    $action_adr = $this->test_url;
                } else {
                    $action_adr = $this->prod_url;
                }
                $action_adr .= 'getOrderStatusExtended.do';

                $args = array(
                    'userName' => $this->merchant,
                    'password' => $this->password,
//                    'orderId' => $args['orderId'] = isset($_GET['mdOrder']) ? $_GET['mdOrder'] : null
                );


                switch ($action) {

                    case "result":
                        //by returnUrl
                        $args['orderId'] = isset($_GET['orderId']) ? $_GET['orderId'] : null;

                        // we already know internal order_id
                        $order_id = $_GET['order_id'];
                        $order = new WC_Order($order_id);

                        $response = $this->_sendData(http_build_query($args, '', '&'), $action_adr);
                        $response = json_decode($response, true);

                        $orderStatus = $response['orderStatus'];

                        if ($orderStatus == '1' || $orderStatus == '2') {

                            if (!empty($this->success_url)) {
                                wp_redirect($this->success_url . "?order_id=" . $order_id);
                                exit;
                            }

                            wp_redirect($this->get_return_url($order));
                            exit;

                        } else {

                            wc_add_notice(__('There was an error while processing payment<br/>' . $response['actionCodeDescription'], 'wc-credibanco-text-domain'), 'error');

                            if (!empty($this->fail_url)) {
                                WC()->cart->empty_cart();
                                wp_redirect($this->fail_url . "?order_id=" . $order_id);
                                exit;
                            }

                            wp_redirect($order->get_cancel_order_url());
                            exit;
                        }

                        break;

                    case "callback":
                        //by callback
                        $args['orderId'] = isset($_GET['mdOrder']) ? $_GET['mdOrder'] : null;

                        $response = $this->_sendData(http_build_query($args, '', '&'), $action_adr);
                        $response = json_decode($response, true);

                        $p = explode("_", $response['orderNumber']);

                        // we will know internal order_id from $response
                        $order_id = $p[0];
                        $order = new WC_Order($order_id);

                        $orderStatus = $response['orderStatus'];

                        if ($orderStatus == '1' || $orderStatus == '2') {

                            $order->update_status($this->order_status, __('Payment successful', 'wc-credibanco-text-domain'));
                            try {
                                wc_reduce_stock_levels($order_id);

                            } catch (Exception $e) {
                                //noop
                            }

                            $order->payment_complete();

                        } else {

                            $order->update_status('failed', __('Payment failed', 'wc-credibanco-text-domain'));
                            add_filter('woocommerce_add_to_cart_message', 'my_cart_messages', 99);
                            $order->cancel_order();

                        }

                        break;
                }

                exit;
            }

        }

        /**
         * Check if this gateway is enabled and available in the user's country
         */
        function is_valid_for_use()
        {
            return true;
        }

        /*
         * Admin Panel Options
         */
        public function admin_options()
        {
            ?>


            <h3><?php echo RBS_CREDIBANCO_PAYMENT_NAME; ?></h3>
            <img src="<?php echo $this->icon_path; ?>"/>
            <p><?php _e("Allow customers to conveniently checkout directly with ", 'wc-credibanco-text-domain'); ?><? echo RBS_CREDIBANCO_PAYMENT_NAME; ?></p>

            <?php if ($this->is_valid_for_use()) : ?>
            <table class="form-table">
                <?php
                // Generate the HTML For the settings form.
                $this->generate_settings_html();
                ?>
            </table>
        <?php else : ?>
            <div class="inline error"><p>
                    <strong><?php _e('Error: ', 'woocommerce'); ?></strong>: <?php echo $this->id; ?><?php _e(' does not support your currency.', 'wc-credibanco-text-domain'); ?>
                </p></div>
            <?php
        endif;

        }

        /*
         * Initialise Gateway Settings Form Fields
         */
        function init_form_fields()
        {

            $form_fields = array(
                'enabled' => array(
                    'title' => __('Enable/Disable', 'wc-credibanco-text-domain'),
                    'type' => 'checkbox',
                    'label' => __('Enable', 'wc-credibanco-text-domain') . " CredibanCo",
                    'default' => 'yes'
                ),
                'title' => array(
                    'title' => __('Title', 'wc-credibanco-text-domain'),
                    'type' => 'text',
                    'description' => __('Title displayed to your customer when they make their order.', 'wc-credibanco-text-domain'),
                    'desc_tip' => true,
                ),
                'merchant' => array(
                    'title' => __('Login-API', 'wc-credibanco-text-domain'),
                    'type' => 'text',
                    'default' => '',
                    'desc_tip' => true,
                ),
                'password' => array(
                    'title' => __('Password', 'wc-credibanco-text-domain'),
                    'type' => 'password',
                    'default' => '',
                    'desc_tip' => true,
                ),
                'test_mode' => array(
                    'title' => __('Test mode', 'wc-credibanco-text-domain'),
                    'type' => 'checkbox',
                    'label' => __('Enable', 'wc-credibanco-text-domain'),
                    'description' => __('In this mode no actual payments are processed.', 'wc-credibanco-text-domain'),
                    'default' => 'no'
                ),
                'stage_mode' => array(
                    'title' => __('Payments type', 'wc-credibanco-text-domain'),
                    'type' => 'select',
                    'class' => 'wc-enhanced-select',
                    'default' => 'one-stage',
                    'options' => array(
                        'one-stage' => __('One-phase payments', 'wc-credibanco-text-domain'),
                        'two-stage' => __('Two-phase payments', 'wc-credibanco-text-domain'),
                    ),
                ),
                'description' => array(
                    'title' => __('Description', 'wc-credibanco-text-domain'),
                    'type' => 'textarea',
                    'description' => __('Payment description displayed to your customer.', 'wc-credibanco-text-domain'),

                ),
                'order_status' => array(
                    'title' => __('Payed order status', 'wc-credibanco-text-domain'),
                    'type' => 'select',
                    'class' => 'wc-enhanced-select',
//todo                    'description' => __('Payed order status.', 'wc-credibanco-text-domain'),
                    'default' => 'wc-completed',
                    'desc_tip' => true,
                    'options' => array(
                        'wc-processing' => _x('Processing', 'Order status', 'woocommerce'),
                        'wc-completed' => _x('Completed', 'Order status', 'woocommerce'),
                    ),
                ),

                'success_url' => array(
                    'title' => __('success_url', 'wc-credibanco-text-domain'),
                    'type' => 'text',
                    'description' => __('Page your customer will be redirected to after a <b>successful payment</b>.<br/>Leave this field blank, if you want to use default settings.', 'wc-credibanco-text-domain'),
                ),
                'fail_url' => array(
                    'title' => __('fail_url', 'wc-credibanco-text-domain'),
                    'type' => 'text',
                    'description' => __('Page your customer will be redirected to after an <b>unsuccessful payment</b>.<br/>Leave this field blank, if you want to use default settings.', 'wc-credibanco-text-domain'),
                ),

//                'installments' => array(
//                    'title' => __("installments", 'wc-credibanco-text-domain'),
//                    'type' => 'text',
//                    'description' => __('(Can be 1 - 36)', 'wc-credibanco-text-domain'),
//                    'default' => 1
//                ),

            );

            $form_fields_ext = array(

                'send_order' => array(
                    'title' => __("Send cart data<br />(including customer info)", 'wc-credibanco-text-domain'),
                    'type' => 'checkbox',
                    'label' => __('Enable', 'wc-credibanco-text-domain'),
                    'description' => __('If this option is enabled order receipts will be created and sent to your customer and to the revenue service.<br/>This is a paid option, contact your bank to enable it. If you use it, configure VAT settings. VAT is calculated according to the Russian legislation. VAT amounts calculated by your store may differ from the actual VAT amounts that can be applied.', 'wc-credibanco-text-domain'),
                    'default' => 'no'
                )
            );

            if (defined("RBS_CREDIBANCO_EXT_FIELDS") && RBS_CREDIBANCO_EXT_FIELDS === true) {
                $form_fields = array_merge($form_fields, $form_fields_ext);
            }

            $this->form_fields = $form_fields;
        }

        function get_product_price_with_discount($price, $type, $c_amount, &$order_data)
        {

            switch ($type) {
                case 'percent':
                    $new_price = ceil($price * (1 - $c_amount / 100));

                    // remove this discount from discount_total
                    $order_data['discount_total'] -= ($price - $new_price);
                    break;

                case 'fixed_product':
                    $new_price = $price - $c_amount;

                    // remove this discount from discount_total
                    $order_data['discount_total'] -= $c_amount / 100;
                    break;

                default:
                    $new_price = $price;
            }
            return $new_price;
        }

        /*
         * Generate the dibs button link
         */
        public function generate_form($order_id)
        {
            $order = new WC_Order($order_id);

            $amount = $order->get_total() * 100;

            // COUPONS
            $coupons = array();
            global $woocommerce;
            if (!empty($woocommerce->cart->applied_coupons)) {
                foreach ($woocommerce->cart->applied_coupons as $code) {
                    $coupons[] = new WC_Coupon($code);
                }
            }

            if ($this->test_mode == 'yes') {
                $action_adr = $this->test_url;
            } else {
                $action_adr = $this->prod_url;
            }

            if ($this->stage_mode == 'two-stage') {
                $action_adr .= 'registerPreAuth.do';
            } else if ($this->stage_mode == 'one-stage') {
                $action_adr .= 'register.do';
            }

            $order_data = $order->get_data();

            $language = substr(get_bloginfo("language"), 0, 2);
            //fix Gate bug locale2country
            switch ($language) {
                case  ('uk'):
                    $language = 'ua';
                    break;
                case ('be'):
                    $language = 'by';
                    break;
            }

            $jsonParams_array = array(
                'CMS' => 'Wordpress ' . get_bloginfo('version') . " + woocommerce version: " . wpbo_get_woo_version_number(),
                'Module-Version' => 'CredibanCo ' . $this->pData['Version'],
            );

            if (!empty($order_data['billing']['email'])) {
                $jsonParams_array['email'] = $order_data['billing']['email'];
            }
            if (!empty($order_data['billing']['phone'])) {
                $jsonParams_array['phone'] = "+" . preg_replace("/(\W*)/", "", $order_data['billing']['phone']);
            }

            if (!empty($order_data['billing']['address_1'])) {
                $jsonParams_array['postAddress'] = $order_data['billing']['address_1'];
            }
            if (!empty($order_data['billing']['city'])) {
                $jsonParams_array['payerCity'] = $order_data['billing']['city'];
            }
            if (!empty($order_data['billing']['state'])) {
                $jsonParams_array['payerState'] = $order_data['billing']['state'];
            }
            if (!empty($order_data['billing']['postcode'])) {
                $jsonParams_array['payerPostalCode'] = $order_data['billing']['postcode'];
            }
            if (!empty($order_data['billing']['country'])) {
                $jsonParams_array['payerCountry'] = $order_data['billing']['country'];
            }

            if (!empty($order_data['shipping']['address_1'])) {
                $jsonParams_array['shippingAddress'] = $order_data['shipping']['address_1'];
            }

            // Loop through order tax items
            foreach ($order->get_items('tax') as $item) {

                if (strtolower($item->get_label()) == "iva") {
                    $jsonParams_array["IVA.amount"] = $item->get_tax_total() * 100;
                }

                if (strtolower($item->get_label()) == "iac") {
                    $jsonParams_array["IAC.amount"] = $item->get_tax_total() * 100;
                }
            }

            // prepare args array
            $args = array(
                'orderNumber' => $order_id . '_' . time(),
                'userName' => $this->merchant,
                'password' => $this->password,
                'amount' => $amount,
                'language' => 'es', //$language,
                'returnUrl' => get_option('siteurl') . '?wc-api=WC_RBSPayment_credibanco&credibanco=result&order_id=' . $order_id,
//                'currency' => $this->currency_codes[get_woocommerce_currency()],
                'jsonParams' => json_encode($jsonParams_array),
            );

            $headers = array(
                'CMS: Wordpress ' . get_bloginfo('version') . " + woocommerce version: " . wpbo_get_woo_version_number(),
                'Module-Version: ' . $this->pData['Version'],
            );
            $response = $this->_sendData(http_build_query($args, '', '&'), $action_adr, $headers);

            $response = json_decode($response, true);


            if (empty($response['errorCode'])) {

                wp_redirect($response['formUrl']);

                //EI: if is error in the headers (already send)
                echo '<p><a class="button cancel" href="' . $response['formUrl'] . '">' . __('Proceed with payment', 'wc-credibanco-text-domain') . '</a></p>';
                exit;

            } else {
                return '<p>' . __('Error code #' . $response['errorCode'] . ': ' . $response['errorMessage'], 'wc-credibanco-text-domain') . '</p>' .
                '<a class="button cancel" href="' . $order->get_cancel_order_url() . '">' . __('Cancel payment and return to cart', 'wc-credibanco-text-domain') . '</a>';
            }
        }


        function correctBundleItem(&$item, $discount)
        {

            $item['itemAmount'] -= $discount;
            $item['itemPrice'] = $item['itemAmount'] % $item['quantity']['value'];
            if ($item['itemPrice'] != 0) {
                $item['itemAmount'] += $item['quantity']['value'] - $item['itemPrice'];
            }

            $item['itemPrice'] = $item['itemAmount'] / $item['quantity']['value'];
        }


        /*
         * Process the payment and return the result
         */
        function process_payment($order_id)
        {
            $order = new WC_Order($order_id);

            //if PLUG-2403
            if (!empty($_GET['pay_for_order']) && $_GET['pay_for_order'] == 'true') {
                $this->generate_form($order_id);
                die;
            }

            $pay_now_url = esc_url($order->get_checkout_payment_url(true));

            return array(
                'result' => 'success',
                'redirect' => $pay_now_url
            );

        }

        /*
         * Receipt page
         */
        function receipt_page($order)
        {
            echo $this->generate_form($order);
        }

        function rbs_logger($var, $info = false)
        {
            $information = "";
            if ($var) {
                if ($info) {
                    $information = "\n\n";
                    $information .= str_repeat("-=", 64);
                    $information .= "\nDate: " . date('Y-m-d H:i:s');
                    $information .= "\nWordpress version " . get_bloginfo('version') . "; Woocommerce version: " . wpbo_get_woo_version_number() . "\n";
                }

                $result = $var;
                if (is_array($var) || is_object($var)) {
                    $result = "\n" . print_r($var, true);
                }
                $result .= "\n\n";
                $path = dirname(__FILE__) . '/wc_rbspayment.log';
                error_log($information . $result, 3, $path);
                return true;
            }
            return false;
        }

    }

    add_filter('woocommerce_payment_gateways', 'add_rbspayment_credibanco_gateway');
    function add_rbspayment_credibanco_gateway($methods)
    {
        $methods[] = 'WC_RBSPayment_credibanco';
        return $methods;
    }


    if (!function_exists('wpbo_get_woo_version_number')) {
        function wpbo_get_woo_version_number()
        {
            // If get_plugins() isn't available, require it
            if (!function_exists('get_plugins'))
                require_once(ABSPATH . 'wp-admin/includes/plugin.php');

            // Create the plugins folder and file variables
            $plugin_folder = get_plugins('/' . 'woocommerce');
            $plugin_file = 'woocommerce.php';

            // If the plugin version number is set, return it
            if (isset($plugin_folder[$plugin_file]['Version'])) {
                return $plugin_folder[$plugin_file]['Version'];

            } else {
                // Otherwise return null
                return NULL;
            }
        }
    }


}