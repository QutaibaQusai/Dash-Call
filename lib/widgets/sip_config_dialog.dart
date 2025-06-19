// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../services/sip_service.dart';

// class SipConfigDialog extends StatefulWidget {
//   const SipConfigDialog({super.key});

//   @override
//   State<SipConfigDialog> createState() => _SipConfigDialogState();
// }

// class _SipConfigDialogState extends State<SipConfigDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _serverController;
//   late TextEditingController _usernameController;
//   late TextEditingController _passwordController;
//   late TextEditingController _domainController;
//   late TextEditingController _portController;

//   @override
//   void initState() {
//     super.initState();
//     final sipService = Provider.of<SipService>(context, listen: false);
    
//     _serverController = TextEditingController(text: sipService.sipServer);
//     _usernameController = TextEditingController(text: sipService.username);
//     _passwordController = TextEditingController(text: sipService.password);
//     _domainController = TextEditingController(text: sipService.domain);
//     _portController = TextEditingController(text: sipService.port.toString());
//   }

//   @override
//   void dispose() {
//     _serverController.dispose();
//     _usernameController.dispose();
//     _passwordController.dispose();
//     _domainController.dispose();
//     _portController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('DashCall Configuration'),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Server
//                 TextFormField(
//                   controller: _serverController,
//                   decoration: const InputDecoration(
//                     labelText: 'Asterisk Server *',
//                     hintText: 'asterisk.yourcompany.com',
//                     border: OutlineInputBorder(),
//                     helperText: 'Your Asterisk server address',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter Asterisk server address';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Port
//                 TextFormField(
//                   controller: _portController,
//                   decoration: const InputDecoration(
//                     labelText: 'Port',
//                     hintText: '5060',
//                     border: OutlineInputBorder(),
//                     helperText: 'SIP port (usually 5060)',
//                   ),
//                   keyboardType: TextInputType.number,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter port';
//                     }
//                     final port = int.tryParse(value);
//                     if (port == null || port < 1 || port > 65535) {
//                       return 'Please enter a valid port (1-65535)';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Username
//                 TextFormField(
//                   controller: _usernameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Extension/Username *',
//                     hintText: '101',
//                     border: OutlineInputBorder(),
//                     helperText: 'Your extension number or SIP username',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter extension or username';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Password
//                 TextFormField(
//                   controller: _passwordController,
//                   decoration: const InputDecoration(
//                     labelText: 'Password *',
//                     border: OutlineInputBorder(),
//                     helperText: 'SIP password for this extension',
//                   ),
//                   obscureText: false,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter password';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Domain (optional)
//                 TextFormField(
//                   controller: _domainController,
//                   decoration: const InputDecoration(
//                     labelText: 'Domain (optional)',
//                     hintText: 'Leave empty to use server address',
//                     border: OutlineInputBorder(),
//                     helperText: 'SIP domain (optional)',
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//               ],
//             ),
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _saveConfiguration,
//           child: const Text('Save & Connect'),
//         ),
//       ],
//     );
//   }

//   void _saveConfiguration() async {
//     if (!_formKey.currentState!.validate()) return;

//     final sipService = Provider.of<SipService>(context, listen: false);
    
//     // Save settings
//     await sipService.saveSettings(
//       _serverController.text.trim(),
//       _usernameController.text.trim(),
//       _passwordController.text.trim(),
//       _domainController.text.trim(),
//       int.parse(_portController.text.trim()),
//     );

//     if (mounted) {
//       Navigator.pop(context);
      
//       // Attempt to register
//       final success = await sipService.register();
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               success 
//                   ? 'Configuration saved! Connecting to Asterisk...' 
//                   : 'Configuration saved but connection failed. Check settings.',
//             ),
//             backgroundColor: success ? Colors.green : Colors.orange,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }
// }