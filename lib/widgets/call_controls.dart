// // widgets/call_controls.dart
// import 'package:dash_call/services/sip_service.dart';
// import 'package:flutter/material.dart';

// class CallControls extends StatelessWidget {
//   final SipService sipService;

//   const CallControls({super.key, required this.sipService});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Call status and number
//           Card(
//             elevation: 4,
//             child: Padding(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 children: [
//                   Text(
//                     _getCallStatusText(),
//                     style: Theme.of(context).textTheme.headlineSmall,
//                   ),
//                   if (sipService.callNumber != null) ...[
//                     const SizedBox(height: 8),
//                     Text(
//                       sipService.callNumber!,
//                       style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                   if (sipService.callStartTime != null && 
//                       sipService.callStatus == CallStatus.active) ...[
//                     const SizedBox(height: 16),
//                     StreamBuilder(
//                       stream: Stream.periodic(const Duration(seconds: 1)),
//                       builder: (context, snapshot) {
//                         final duration = DateTime.now().difference(sipService.callStartTime!);
//                         return Text(
//                           _formatDuration(duration),
//                           style: Theme.of(context).textTheme.titleLarge,
//                         );
//                       },
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
          
//           const SizedBox(height: 32),
          
//           // Control buttons based on call status
//           if (sipService.callStatus == CallStatus.incoming) ...[
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // Reject button
//                 FloatingActionButton.large(
//                   onPressed: sipService.rejectCall,
//                   backgroundColor: Colors.red,
//                   heroTag: "reject",
//                   child: const Icon(Icons.call_end, color: Colors.white, size: 36),
//                 ),
//                 // Answer button
//                 FloatingActionButton.large(
//                   onPressed: sipService.answerCall,
//                   backgroundColor: Colors.green,
//                   heroTag: "answer",
//                   child: const Icon(Icons.call, color: Colors.white, size: 36),
//                 ),
//               ],
//             ),
//           ] else if (sipService.callStatus == CallStatus.active || 
//                     sipService.callStatus == CallStatus.held) ...[
//             Column(
//               children: [
//                 // Hold/Resume and Hangup
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     // Hold/Resume button
//                     FloatingActionButton(
//                       onPressed: sipService.callStatus == CallStatus.active
//                           ? sipService.holdCall
//                           : sipService.resumeCall,
//                       backgroundColor: sipService.callStatus == CallStatus.held
//                           ? Colors.green
//                           : Colors.orange,
//                       heroTag: "hold",
//                       child: Icon(
//                         sipService.callStatus == CallStatus.held
//                             ? Icons.play_arrow
//                             : Icons.pause,
//                         color: Colors.white,
//                       ),
//                     ),
//                     // Hangup button
//                     FloatingActionButton.large(
//                       onPressed: sipService.hangupCall,
//                       backgroundColor: Colors.red,
//                       heroTag: "hangup",
//                       child: const Icon(Icons.call_end, color: Colors.white, size: 36),
//                     ),
//                   ],
//                 ),
                
//                 const SizedBox(height: 24),
                
//                 // DTMF Dialer for active calls
//                 if (sipService.callStatus == CallStatus.active)
//                   _buildDTMFPad(),
//               ],
//             ),
//           ] else if (sipService.callStatus == CallStatus.calling) ...[
//             Column(
//               children: [
//                 const CircularProgressIndicator(),
//                 const SizedBox(height: 16),
//                 FloatingActionButton.large(
//                   onPressed: sipService.hangupCall,
//                   backgroundColor: Colors.red,
//                   heroTag: "cancel",
//                   child: const Icon(Icons.call_end, color: Colors.white, size: 36),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildDTMFPad() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text(
//               'DTMF Keypad',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 16),
//             GridView.count(
//               shrinkWrap: true,
//               crossAxisCount: 3,
//               childAspectRatio: 1.5,
//               mainAxisSpacing: 8,
//               crossAxisSpacing: 8,
//               children: [
//                 '1', '2', '3',
//                 '4', '5', '6',
//                 '7', '8', '9',
//                 '*', '0', '#',
//               ].map((dtmf) => _buildDTMFButton(dtmf)).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDTMFButton(String dtmf) {
//     return ElevatedButton(
//       onPressed: () => sipService.sendDTMF(dtmf),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.grey.shade100,
//         foregroundColor: Colors.black87,
//       ),
//       child: Text(
//         dtmf,
//         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   String _getCallStatusText() {
//     switch (sipService.callStatus) {
//       case CallStatus.calling:
//         return 'Calling...';
//       case CallStatus.incoming:
//         return 'Incoming Call';
//       case CallStatus.active:
//         return 'Connected';
//       case CallStatus.held:
//         return 'On Hold';
//       default:
//         return 'Call';
//     }
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
    
//     if (duration.inHours > 0) {
//       final hours = twoDigits(duration.inHours);
//       return '$hours:$minutes:$seconds';
//     } else {
//       return '$minutes:$seconds';
//     }
//   }
// }