import 'dart:async';

enum PromiseStatus { PENDING, RESOLVED, REJECTED }

typedef Func(Object val);

class Promise {
  PromiseStatus _status = PromiseStatus.PENDING;
  dynamic _value;
  dynamic _reason;
  List<Func> _rejectedCallbacks = [];
  List<Func> _resolvedCallbacks = [];

  get value {
    return _value;
  }

  get reason {
    return _reason;
  }

  PromiseStatus get status {
    return _status;
  }

  Promise(dynamic excutor(dynamic resolve(val), dynamic reject(val))) {
    if (!(excutor is Function)) {
      throw  AssertionError('Promise resolver $excutor is not a function');
    }
    try {
      excutor(_resolve, _reject);
    } catch (e) {
      _reject(e);
    }
  }

  _resolve(value) {
    if (status == PromiseStatus.PENDING) {
      _value = value;
      _status = PromiseStatus.RESOLVED;
      _resolvedCallbacks.forEach((fn) {
        fn(value);
      });
    }
  }

  _reject(reason) {
    if (status == PromiseStatus.PENDING) {
      _reason = reason;
      _status = PromiseStatus.REJECTED;
      _rejectedCallbacks.forEach((fn) => fn(reason));
    }
  }

  Promise then(Func onFulfilled, [Func onRejected]) {
    if (!(onFulfilled is Function)) {
      onFulfilled = (val) => val;
    }
    if (!(onRejected is Function)) {
      onRejected = (err) => throw err;
    }
    Promise promise2;
    promise2 =  Promise((resolve, reject) {
      if (status == PromiseStatus.RESOLVED) {
        Future.sync(() {
          try {
            final x = onFulfilled(_value);
            Promise.resolvePromise(promise2, x, resolve, reject);
          } catch (e) {
            reject(e);
          }
        });
      } else if (status == PromiseStatus.REJECTED) {
        Future.sync(() {
          try {
            final x = onRejected(_reason);
            Promise.resolvePromise(promise2, x, resolve, reject);
          } catch (e) {
            reject(e);
          }
        });
      } else if (status == PromiseStatus.PENDING) {
        _resolvedCallbacks.add((val) {
          Future.sync(() {
            try {
              final x = onFulfilled(val);
              Promise.resolvePromise(promise2, x, resolve, reject);
            } catch (e) {
              reject(e);
            }
          });
        });
        _rejectedCallbacks.add((reason) {
          Future.sync(() {
            try {
              final x = onRejected(reason);
              Promise.resolvePromise(promise2, x, resolve, reject);
            } catch (e) {
              reject(e);
            }
          });
        });
      }
    });
    return promise2;
  }

  static void resolvePromise(
      Promise promise2, dynamic x, Func resolve, Func reject) {
    if (promise2 == x) {
      reject( AssertionError('Chaining cycle detected for promise'));
      return;
    }
    bool called = false;
    if (x != null && (x is Promise)) {
      try {
        x.then((val) {
          if (called) return;
          called = true;
          Promise.resolvePromise(promise2, val, resolve, reject);
        }, (err) {
          if (called) return;
          called = true;
          reject(err);
        });
      } catch (e) {
        if (called) return;
        called = true;
        reject(e);
      }
    } else {
      resolve(x);
    }
  }

  Promise catchError(Func onRejected) {
    return then(null, onRejected);
  }

  Promise always(Function callback) {
    return then((value) {
      Promise.resolve(callback()).then((_) => value);
    }, (reason) {
      Promise.reject(callback()).catchError((_) => throw reason);
    });
  }

  static Promise resolve(value) {
    return  Promise((resolve, reject) {
      resolve(value);
    });
  }

  static Promise reject(reason) {
    return Promise((_, reject) {
      reject(reason);
    });
  }

  static Promise race(List<Promise> promises) {
    return  Promise((resolve, reject) {
      promises.forEach((promise) {
        promise.then(resolve, reject);
      });
    });
  }

  static Promise all(List<Promise> promises) {
    final length = promises.length;
    int _i = 0;
    return Promise((resolve, reject) {
      promises.forEach((promise) {
        promise.then((val) {
          _i++;
          if (_i == length) {
            resolve(promises.map((promise) => promise.value));
          }
        }, reject);
      });
    });
  }

  static Promise sequence(List<dynamic> defers) {
    final _l = defers.length;
     
    var res=Promise((resolve, reject) {
      int _i=-1; 
      void run(var before)
      {
          if(_i++>=_l-1){
           resolve(before);   
            return;
          }
        defers[_i]().then(run).catchError(reject);
        
      }
        run(null);
    });

    return res;
  }
  

}
