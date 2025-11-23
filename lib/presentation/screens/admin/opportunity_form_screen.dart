import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/opportunity.dart';
import '../../blocs/admin_opportunities/admin_opportunities_bloc.dart';

class OpportunityFormScreen extends StatefulWidget {
  final Opportunity? opportunity;

  const OpportunityFormScreen({super.key, this.opportunity});

  @override
  State<OpportunityFormScreen> createState() => _OpportunityFormScreenState();
}

class _OpportunityFormScreenState extends State<OpportunityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _timeCommitmentController;
  late TextEditingController _requirementsController;

  String _selectedCategory = 'Environment';
  String? _imageBase64;
  bool _isUploadingImage = false;

  final List<String> _categories = [
    'Environment',
    'Education',
    'Health',
    'Arts & Culture',
    'Community',
    'Animals',
  ];

  bool get isEditMode => widget.opportunity != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.opportunity?.title ?? '');
    _descriptionController = TextEditingController(text: widget.opportunity?.description ?? '');
    _locationController = TextEditingController(text: widget.opportunity?.location ?? '');
    _timeCommitmentController = TextEditingController(text: widget.opportunity?.timeCommitment ?? '');
    _requirementsController = TextEditingController(text: widget.opportunity?.requirements ?? '');
    
    if (widget.opportunity != null) {
      _selectedCategory = widget.opportunity!.category;
      _imageBase64 = widget.opportunity!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isUploadingImage = true);
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      setState(() {
        _imageBase64 = base64Image;
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded successfully!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Opportunity' : 'Create Opportunity'),
      ),
      body: BlocListener<AdminOpportunitiesBloc, AdminOpportunitiesState>(
        listener: (context, state) {
          if (state is AdminOpportunityOperationSuccess) {
            context.go('/admin/dashboard');
          } else if (state is AdminOpportunitiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditMode ? 'Update opportunity details' : 'Enter opportunity details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                
                // Image Upload Section
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.lightGreen, width: 2),
                    ),
                    child: _isUploadingImage
                        ? const Center(child: CircularProgressIndicator())
                        : _imageBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _imageBase64!.startsWith('data:image')
                                    ? Image.memory(
                                        base64Decode(_imageBase64!.split(',')[1]),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Image.network(
                                        _imageBase64!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 64,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap to upload image',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Community Garden Assistant',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe the volunteering opportunity',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    hintText: 'e.g., Central Park Community Garden',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Time Commitment
                TextFormField(
                  controller: _timeCommitmentController,
                  decoration: const InputDecoration(
                    labelText: 'Time Commitment *',
                    hintText: 'e.g., 2 hours/week',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter time commitment';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Requirements
                TextFormField(
                  controller: _requirementsController,
                  decoration: const InputDecoration(
                    labelText: 'Requirements *',
                    hintText: 'e.g., Age 16+, Enthusiasm',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter requirements';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                BlocBuilder<AdminOpportunitiesBloc, AdminOpportunitiesState>(
                  builder: (context, state) {
                    final isLoading = state is AdminOpportunitiesLoading;
                    
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submitForm,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditMode ? 'Update Opportunity' : 'Create Opportunity'),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Cancel Button
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryGreen),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_imageBase64 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload an image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final opportunity = Opportunity(
        id: widget.opportunity?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        timeCommitment: _timeCommitmentController.text.trim(),
        requirements: _requirementsController.text.trim(),
        imageUrl: _imageBase64!,
      );

      if (isEditMode) {
        context.read<AdminOpportunitiesBloc>().add(UpdateOpportunity(opportunity));
      } else {
        context.read<AdminOpportunitiesBloc>().add(CreateOpportunity(opportunity));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _timeCommitmentController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }
}