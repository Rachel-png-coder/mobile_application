import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _listings => _firestore.collection('listings');

  Future<Map<String, dynamic>> createListing(Listing listing) async {
    try {
      print('🚀 Creating listing: ${listing.name}');
      print('📊 User ID: ${_auth.currentUser?.uid}');
      print('📝 CreatedBy in listing: ${listing.createdBy}');

      DocumentReference docRef = await _listings.add(listing.toMap());
      print('✅ Created with ID: ${docRef.id}');
      return {'success': true, 'id': docRef.id};
    } catch (e) {
      print('❌ Create error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Stream<List<Listing>> getAllListings() {
    print('📡 Setting up getAllListings stream');
    return _listings.orderBy('timestamp', descending: true).snapshots().map((
      snapshot,
    ) {
      print('📥 Firestore snapshot received with ${snapshot.docs.length} docs');
      return snapshot.docs.map((doc) {
        // Fix: Safely cast the data to Map<String, dynamic>
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          print('⚠️ Document ${doc.id} has null data');
          return Listing.fromMap(doc.id, {});
        }
        return Listing.fromMap(doc.id, data);
      }).toList();
    });
  }

  Stream<List<Listing>> getUserListings() {
    final userId = _auth.currentUser?.uid;
    print('👤 Getting listings for user: $userId');

    if (userId == null || userId.isEmpty) {
      print('⚠️ No user logged in, returning empty stream');
      return Stream.value([]);
    }

    return _listings
        .where('createdBy', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          print(
            '📥 User listings snapshot: ${snapshot.docs.length} docs for user $userId',
          );

          // Debug: Print each listing's createdBy
          for (var doc in snapshot.docs) {
            // Fix: Safely cast the data
            final data = doc.data() as Map<String, dynamic>?;
            print('   📄 Doc ${doc.id}: createdBy=${data?['createdBy']}');
          }

          return snapshot.docs.map((doc) {
            // Fix: Safely cast the data
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              print('⚠️ Document ${doc.id} has null data');
              return Listing.fromMap(doc.id, {});
            }
            return Listing.fromMap(doc.id, data);
          }).toList();
        });
  }

  Future<Map<String, dynamic>> updateListing(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      print('✏️ Updating listing: $id');
      await _listings.doc(id).update(data);
      print('✅ Update successful');
      return {'success': true};
    } catch (e) {
      print('❌ Update error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteListing(String id) async {
    try {
      print('🗑️ Deleting listing: $id');
      await _listings.doc(id).delete();
      print('✅ Delete successful');
      return {'success': true};
    } catch (e) {
      print('❌ Delete error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Listing?> getListing(String id) async {
    try {
      print('🔍 Getting listing: $id');
      DocumentSnapshot doc = await _listings.doc(id).get();
      if (doc.exists) {
        print('✅ Found listing');
        // Fix: Safely cast the data
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          print('⚠️ Document $id has null data');
          return null;
        }
        return Listing.fromMap(doc.id, data);
      }
      print('⚠️ Listing not found');
      return null;
    } catch (e) {
      print('❌ Error getting listing: $e');
      return null;
    }
  }
}
