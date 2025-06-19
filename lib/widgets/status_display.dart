// // widgets/status_display.dart
// import 'package:flutter/material.dart';
// import '../services/sip_service.dart';

// class StatusDisplay extends StatelessWidget {
//   final SipService sipService;

//   const StatusDisplay({super.key, required this.sipService});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: _getStatusColor().withOpacity(0.1),
//         border: Border.all(color: _getStatusColor()),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Icon(_getStatusIcon(), color: _getStatusColor()),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   _getStatusText(),
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: _getStatusColor(),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (sipService.statusMessage != null) ...[
//             const SizedBox(height: 8),
//             Text(
//               sipService.statusMessage!,
//               style: const TextStyle(fontSize: 12),
//               textAlign: TextAlign.center,
//             ),
//           ],
//           if (sipService.callStatus != CallStatus.idle) ...[
//             const SizedBox(height: 8),
//             _buildCallInfo(),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildCallInfo() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         if (sipService.callNumber != null)
//           Text(
//             'Number: ${sipService.callNumber}',
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//         if (sipService.callStartTime != null && sipService.callStatus == CallStatus.active)
//           StreamBuilder(
//             stream: Stream.periodic(const Duration(seconds: 1)),
//             builder: (context, snapshot) {
//               final duration = DateTime.now().difference(sipService.callStartTime!);
//               return Text('Duration: ${_formatDuration(duration)}');
//             },
//           ),
//       ],
//     );
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final hours = twoDigits(duration.inHours);
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
//   }

//   Color _getStatusColor() {
//     switch (sipService.status) {
//       case SipConnectionStatus.connected:
//         return Colors.green;
//       case SipConnectionStatus.connecting:
//         return Colors.orange;
//       case SipConnectionStatus.error:
//         return Colors.red;
//       case SipConnectionStatus.disconnected:
//         return Colors.grey;
//     }
//   }

//   IconData _getStatusIcon() {
//     switch (sipService.status) {
//       case SipConnectionStatus.connected:
//         return Icons.check_circle;
//       case SipConnectionStatus.connecting:
//         return Icons.sync;
//       case SipConnectionStatus.error:
//         return Icons.error;
//       case SipConnectionStatus.disconnected:
//         return Icons.circle_outlined;
//     }
//   }

//   String _getStatusText() {
//     switch (sipService.status) {
//       case SipConnectionStatus.connected:
//         return 'Connected to ${sipService.sipServer}';
//       case SipConnectionStatus.connecting:
//         return 'Connecting...';
//       case SipConnectionStatus.error:
//         return 'Connection Error';
//       case SipConnectionStatus.disconnected:
//         return 'Not Connected - Configure Settings';
//     }
//   }
// }
