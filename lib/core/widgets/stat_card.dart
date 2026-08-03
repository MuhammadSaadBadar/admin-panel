// import 'package:flutter/material.dart';

// import '../constants/color_constants.dart';

// class StatCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final IconData icon;
//   final Color? color;
//   final double? change;
//   final VoidCallback? onTap;

//   const StatCard({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.icon,
//     this.color,
//     this.change,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: (color ?? ColorConstants.primary).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       icon,
//                       color: color ?? ColorConstants.primary,
//                       size: 24,
//                     ),
//                   ),
//                   if (change != null)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color:
//                             (change! >= 0
//                                     ? ColorConstants.success
//                                     : ColorConstants.error)
//                                 .withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             change! >= 0
//                                 ? Icons.trending_up
//                                 : Icons.trending_down,
//                             size: 16,
//                             color: change! >= 0
//                                 ? ColorConstants.success
//                                 : ColorConstants.error,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${change!.abs().toStringAsFixed(1)}%',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: change! >= 0
//                                   ? ColorConstants.success
//                                   : ColorConstants.error,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 value,
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(title, style: Theme.of(context).textTheme.bodyMedium),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
