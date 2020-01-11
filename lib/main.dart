import 'dart:async';

import 'lib/promise.dart';


 
Promise fail(int seconds, String val) {
  return Promise((_, reject) {
    Timer(Duration(seconds: seconds), () {
      reject(val);
    });  
  }); 
}

Promise delay(int seconds, String val) {
  return Promise((resolve, _) {
    print('start delay $val after $seconds');
    Timer(Duration(seconds: seconds), () {
      print('resolved $val after $seconds');
      resolve(val);
    });
  });
}
void main() {
  //test sequence of defered calls
    var _a=[ defer,defer2,defer,defer2];
    Promise.sequence(_a).then((val) {
    print('sequence: $val');
  }).catchError(print);


   

}
Promise defer()
{
  return delay(1,'Case11 delay');
}
Promise defer2()
{
  return fail(2,'Case fail');
}
