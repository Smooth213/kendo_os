import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/organization.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(FirebaseFirestore.instance);
});

class OrganizationRepository {
  final FirebaseFirestore _firestore;
  OrganizationRepository(this._firestore);

  // 組織一覧をリアルタイム取得
  Stream<List<Organization>> watchOrganizations() {
    return _firestore.collection('organizations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Organization.fromJson(data);
      }).toList();
    });
  }

  // 画面側（MasterManagementScreen）が求めているメソッド名に合わせます
  Future<void> saveOrganization(Organization org) async {
    if (org.id.isEmpty) {
      await _firestore.collection('organizations').add(org.toJson()..remove('id'));
    } else {
      await _firestore.collection('organizations').doc(org.id).set(org.toJson());
    }
  }

  // 選手（名前）を追加する
  Future<void> addPlayer(String orgId, String playerName) async {
    await _firestore.collection('organizations').doc(orgId).update({
      'memberNames': FieldValue.arrayUnion([playerName]),
    });
  }
  // チームテンプレを取得
  Stream<List<TeamTemplate>> watchTeamTemplates(String orgId) {
    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('teams')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TeamTemplate.fromJson(data);
      }).toList();
    });
  }

  // チームテンプレを保存
  Future<void> saveTeamTemplate(String orgId, TeamTemplate team) async {
    final docRef = team.id.isEmpty
        ? _firestore.collection('organizations').doc(orgId).collection('teams').doc()
        : _firestore.collection('organizations').doc(orgId).collection('teams').doc(team.id);

    // ★ toJsonのマップを直接いじるのではなく、copyWithで安全にidをセットしてから保存する
    final newTeam = team.copyWith(id: docRef.id);
    await docRef.set(newTeam.toJson());
  }
}