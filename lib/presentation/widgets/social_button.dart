import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final Widget icon; // Can be Icon or SvgPicture
  final VoidCallback onTap;

  const SocialButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.withValues(alpha: 0.3)
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          // Subtle shadow
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: icon,
        ),
      ),
    );
  }
}
