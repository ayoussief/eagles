
import 'package:eagles/constants.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final FormFieldSetter<String> onClick; // Change here
  
  String _errorMessage(String str) {
    switch(hint) {
      case "Enter your name" : return "Name is empty";
      case 'Enter your email' : return "Email is empty";
      case 'Enter your Password' : return "Password is empty";
      default:
      return "This field cannot be empty"; 
    }
  }

  const CustomTextField({super.key,required this.onClick, required this.icon, required this.hint});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: TextFormField(
        validator: (value) {
          if(value == null || value.isEmpty){
            return _errorMessage(hint);
          }
          return null;
        },
        onSaved: onClick,
        obscureText: hint == "Enter your Password"? true: false,
        cursorColor: KMainColor,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: KMainColor,
          ),
          filled: true,
          fillColor: KSecondaryColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Colors.white
            )
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Colors.white
            )
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Colors.white
            )
          ),
        ),
      ),
    );
  }
}