/// Growing buffers
///
/// This module defines buffers that grow, with a general element type.
///
/// ## Why?
///
/// Motoko applications expose interfaces that use fixed-size arrays of
/// general (user-defined) elements to represent sets, sequences and maps
/// of application-specific elements.
///
/// The `Array` module focuses on Motoko's builtin arrays, whose size is
/// each fixed.  They do not permit general growth/appending, which is the
/// focus here.
///
/// To create these arrays, and to consume them with ergonomic (imperative) code, and
/// low API friction, developers need _buffers that grow_.
///
/// ## Define `Buf<X>` object type
///
/// A "buffer" is a mutable sequence that grows, either one element at a
/// time, or one (second) buffer at time.
import Prim "mo:prim";

module {

/// Create a buffer represented internally by an mutable array.
///
/// The argument `initCapacity` gives the initial capacity.  Under the
/// interface, the mutable array grows by doubling when this initial
/// capacity is exhausted.
public class Buf<X> (initCapacity : Nat) {
  var count : Nat = 0;
  var elems : [var X] = [var]; // initially empty; allocated upon first `add`

  public func add(elem : X) {
    if (count == elems.size()) {
      let size =
        if (count == 0)
          (if (initCapacity > 0) initCapacity else 1)
        else
          2 * elems.size();
      let elems2 = Prim.Array_init<X>(size, elem);
      var i = 0;
      label l loop {
        if (i >= count) break l;
        elems2[i] := elems[i];
        i += 1;
      };
      elems := elems2;
    };
    elems[count] := elem;
    count += 1;
  };

  public func removeLast() : ?X {
    if (count == 0) null
    else {
      count -= 1;
      ?elems[count]
    };
  };

  public func append(b:Buf<X>) {
    let i = b.vals();
    loop {
      switch (i.next()) {
      case null return;
      case (?x) add(x);
      };
    };
  };

  public func size() : Nat =
    count;

  public func clear() =
    count := 0;

  public func clone() : Buf<X> {
    let c = Buf<X>(elems.size());
    var i = 0;
    label l loop {
      if (i >= count) break l;
      c.add(elems[i]);
      i += 1;
    };
    c
  };

  public func vals() : { next : () -> ?X } = object {
    var pos = 0;
    public func next() : ?X {
      if (pos == count) { null } else {
        let elem = ?elems[pos];
        pos += 1;
        elem
      }
    }
  };

  public func toArray() : [X] =
    // immutable clone of array
    Prim.Array_tabulate<X>(
      count,
      func(x: Nat): X { elems[x] }
    );

  public func toVarArray() : [var X] = {
    if (count == 0) { [var] } else {
      let a = Prim.Array_init<X>(count, elems[0]);
      var i = 0;
      label l loop {
        if (i >= count) break l;
        a[i] := elems[i];
        i += 1;
      };
      a
    }
  };

  public func get(offset : Nat) : X {
    elems[offset]
  };

  public func getOpt(offset : Nat) : ?X {
    if (offset < count) {
      ?elems[offset]
    }
    else {
      null
    }
  };

  public func put(offset : Nat, elem : X) {
    elems[offset] := elem;
  };
};

}
