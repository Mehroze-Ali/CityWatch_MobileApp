import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  ImagePickerService();

  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromCamera() {
    return _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 85,
    );
  }

  Future<XFile?> pickFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
  }
}
