import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/providers/banner_provider.dart';
import '../../data/models/banner_model.dart';
import '../../data/config/image_helper.dart';
import 'skeleton_loader.dart';

class AppBanner extends StatefulWidget {
  final String category;
  final double height;
  final double borderRadius;

  const AppBanner({
    super.key,
    this.category = 'home',
    this.height = 220,
    this.borderRadius = 30,
  });

  @override
  State<AppBanner> createState() => _AppBannerState();
}

class _AppBannerState extends State<AppBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  final List<String> _precachedImages = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<BannerProvider>().loadBanners(widget.category);
    });
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted) return;

      final banners = widget.category == 'home'
          ? context.read<BannerProvider>().homeBanners
          : context.read<BannerProvider>().communityBanners;

      if (banners.isEmpty) return;

      final nextPage = (_currentPage + 1) % banners.length;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _precacheBannerImages(List<BannerModel> banners) {
    for (final banner in banners) {
      if (!_precachedImages.contains(banner.imageUrl)) {
        precacheImage(
          CachedNetworkImageProvider(
              ImageHelper.getProxiedImageUrl(banner.imageUrl)),
          context,
        );
        _precachedImages.add(banner.imageUrl);
      }
    }
  }

  Future<void> _onBannerTap(BannerModel banner) async {
    if (banner.actionType == 'route' && banner.actionTarget != null) {
      context.push(banner.actionTarget!);
    } else if (banner.actionType == 'link' && banner.actionTarget != null) {
      final url = Uri.parse(banner.actionTarget!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BannerProvider>(
      builder: (context, provider, child) {
        final banners = widget.category == 'home'
            ? provider.homeBanners
            : provider.communityBanners;

        if (provider.isLoading && banners.isEmpty) {
          return _buildLoadingPlaceholder();
        }

        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        // Precargar imágenes para transiciones instantáneas
        _precacheBannerImages(banners);

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    _timer?.cancel();
                  } else if (notification is ScrollEndNotification) {
                    _startAutoSlide();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: banners.length,
                  itemBuilder: (context, index) {
                    final banner = banners[index];
                    return GestureDetector(
                      onTap: () => _onBannerTap(banner),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(widget.borderRadius),
                            bottomRight: Radius.circular(widget.borderRadius),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CachedNetworkImage(
                                imageUrl: ImageHelper.getProxiedImageUrl(
                                    banner.imageUrl),
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    _buildLoadingPlaceholder(),
                                fadeInDuration: const Duration(
                                  milliseconds: 300,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      banner.title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.barlow(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    if (banner.subtitle != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        banner.subtitle!,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.questrial(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(banners.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return SkeletonLoader(
      height: widget.height,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(widget.borderRadius),
        bottomRight: Radius.circular(widget.borderRadius),
      ),
    );
  }
}
