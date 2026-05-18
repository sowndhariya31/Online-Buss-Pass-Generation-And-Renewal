import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/api_service.dart';

class ApplyPassScreen extends StatefulWidget {
  @override
  _ApplyPassScreenState createState() => _ApplyPassScreenState();
}

class _ApplyPassScreenState extends State<ApplyPassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _collegeController = TextEditingController();
  final _addressController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  
  XFile? _photo;
  XFile? _idProof;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _validStops = [
    "KOYAMBEDU", "THIRUVANMIYUR", "ISLAND GROUND", "KILAMBAKKAM", "PERAMBUR", "BESANT NAGAR",
    "VILLIVAKKAM", "MAMALLAPURAM", "TOLLGATE", "THIRU.VI.KA.NAGAR", "M.G.R.CENTRAL",
    "TAMBARAM WEST", "ADYAR B.S.", "GUDUVANCHERY", "KOVALAM", "THIRUVOTRIYUR",
    "THIRUPORUR", "KANNAGI NAGAR", "PERUMPAKKAM"
  ];

  Future<void> _pickImage(bool isPhoto) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            children: [
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: Color(0xFF6366F1)),
                ),
                title: Text('Take Live Photo / Scan with Camera', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      setState(() {
                        if (isPhoto) _photo = image;
                        else _idProof = image;
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera access error: $e')));
                  }
                },
              ),
              Divider(color: Colors.white10),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library, color: Color(0xFF10B981)),
                ),
                title: Text('Choose from Photo Gallery', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        if (isPhoto) _photo = image;
                        else _idProof = image;
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gallery access error: $e')));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null || _idProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload both Photo and ID Proof.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fields = {
        'college_name': _collegeController.text,
        'address': _addressController.text,
        'route_from': _fromController.text,
        'route_to': _toController.text,
        'pass_type': 'STUDENT',
      };

      final files = <String, http.MultipartFile>{};
      
      final photoBytes = await _photo!.readAsBytes();
      files['photo'] = http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: _photo!.name,
        contentType: MediaType('image', 'jpeg'),
      );

      final idProofBytes = await _idProof!.readAsBytes();
      files['id_proof'] = http.MultipartFile.fromBytes(
        'id_proof',
        idProofBytes,
        filename: _idProof!.name,
        contentType: MediaType('image', 'jpeg'),
      );

      final response = await ApiService.postMultipart('/passes/apply/', fields, files);

      setState(() => _isLoading = false);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Application submitted successfully!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit application: ${response.body}')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF1E293B).withOpacity(0.9),
          elevation: 0,
          title: Text('Apply for Pass', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.darken),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Student Details', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 24),
                          TextFormField(
                            controller: _collegeController,
                            style: TextStyle(color: Colors.white),
                            decoration: _inputDecoration('College/School Name', Icons.school),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            style: TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Home Address', Icons.home),
                            maxLines: 2,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            dropdownColor: Color(0xFF1E293B),
                            style: TextStyle(color: Colors.white),
                            decoration: _inputDecoration('From Stop', Icons.location_on),
                            items: _validStops.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setState(() => _fromController.text = val!),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            dropdownColor: Color(0xFF1E293B),
                            style: TextStyle(color: Colors.white),
                            decoration: _inputDecoration('To Stop', Icons.flag),
                            items: _validStops.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setState(() => _toController.text = val!),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          SizedBox(height: 24),
                          
                          _buildFilePicker('Student Photo', _photo, () => _pickImage(true)),
                          SizedBox(height: 16),
                          _buildFilePicker('ID Proof (Aadhar/ID)', _idProof, () => _pickImage(false)),
                          
                          SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading 
                                ? CircularProgressIndicator(color: Colors.white) 
                                : Text('Submit Application', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePicker(String label, XFile? file, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
        SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_upload, color: Color(0xFF6366F1)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file == null ? 'Choose File' : file.name,
                    style: TextStyle(color: file == null ? Colors.white38 : Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white10,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF6366F1))),
    );
  }
}
