double mediaSetup(double size, {double? sm, double? md, double? lg} ) {
  
  if (size < 640) {
    // Use small grid
    return sm ?? md ?? lg ?? 1; 
  } else if(size < 1024){
    return md ?? lg ?? sm ?? 1;
  }else{
    return lg ?? md ?? sm ?? 1;
  }
}
