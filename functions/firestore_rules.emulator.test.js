/**
 * @jest-environment node
 */
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  writeBatch,
} = require("firebase/firestore");

const PROJECT_ID = "kendo-os-rules-test";
const RULES_PATH = path.resolve(__dirname, "..", "firestore.rules");

function hashJoinPin(dojoId, rawPin) {
  const payload = `kendo_os:v2:join:${dojoId.trim().toLowerCase()}:${rawPin.trim()}`;
  return crypto.createHash("sha256").update(payload).digest("hex");
}

function hashRolePin(dojoId, roleName, rawPin) {
  const payload = `kendo_os:v2:role:${dojoId.trim().toLowerCase()}:${roleName}:${rawPin.trim()}`;
  return crypto.createHash("sha256").update(payload).digest("hex");
}

describe("firestore.rules セキュリティ・PIN・代表者復旧 実ルールテスト", () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: fs.readFileSync(RULES_PATH, "utf8"),
      },
    });
  });

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  async function seedProtectedDojo(dojoId = "dojo_alpha") {
    const joinHash = hashJoinPin(dojoId, "dojo2026");
    const adminHash = hashRolePin(dojoId, "admin", "9999");
    const operatorHash = hashRolePin(dojoId, "operator", "2468");
    const recorderHash = hashRolePin(dojoId, "recorder", "1357");

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `organizations/${dojoId}`), {
        hasJoinPin: true,
        rolePinPromptCompleted: false,
        securityVersion: 2,
      });
      await setDoc(doc(db, `organizations/${dojoId}/private/security`), {
        joinPinHash: joinHash,
        rolePinHashes: {
          admin: adminHash,
          operator: operatorHash,
          recorder: recorderHash,
        },
      });
      await setDoc(doc(db, `organizations/${dojoId}/private/admin_vault`), {
        ciphertext: "v1:seeded:ciphertext:mac",
        version: 1,
      });
      await setDoc(doc(db, `organizations/${dojoId}/tournaments/tourney_1`), {
        name: "春季大会",
      });
      await setDoc(doc(db, `organizations/${dojoId}/tournaments/tourney_2`), {
        name: "秋季大会",
      });
    });

    return { joinHash, adminHash, operatorHash, recorderHash };
  }

  test("未認証ユーザーと直接の private/security 読み取りが拒否される", async () => {
    await seedProtectedDojo("dojo_sec");
    const unauthDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(unauthDb, "organizations/dojo_sec")));

    const authedDb = testEnv.authenticatedContext("user_1").firestore();
    await assertSucceeds(getDoc(doc(authedDb, "organizations/dojo_sec")));
    await assertFails(
      getDoc(doc(authedDb, "organizations/dojo_sec/private/security"))
    );
  });

  test("道場新規創設バッチが通り、誤PIN参加・無認証Admin昇格が拒否される", async () => {
    const dojoId = "new_dojo";
    const joinHash = hashJoinPin(dojoId, "pass2026");
    const adminHash = hashRolePin(dojoId, "admin", "9999");

    const creatorDb = testEnv.authenticatedContext("creator_uid").firestore();
    const createBatch = writeBatch(creatorDb);
    createBatch.set(doc(creatorDb, `organizations/${dojoId}`), {
      hasJoinPin: true,
      rolePinPromptCompleted: false,
      securityVersion: 2,
    });
    createBatch.set(doc(creatorDb, `organizations/${dojoId}/private/security`), {
      joinPinHash: joinHash,
      rolePinHashes: {
        admin: adminHash,
        operator: hashRolePin(dojoId, "operator", "2468"),
        recorder: hashRolePin(dojoId, "recorder", "1357"),
      },
    });
    createBatch.set(
      doc(creatorDb, `organizations/${dojoId}/private/admin_vault`),
      { ciphertext: "v1:init", version: 1 }
    );
    createBatch.set(
      doc(creatorDb, `organizations/${dojoId}/members/creator_uid`),
      {
        role: "viewer",
        accessScope: "dojo",
        submittedJoinPinHash: joinHash,
      }
    );
    await assertSucceeds(createBatch.commit());

    // 誤った入室PINでの自己登録は拒否
    const guestDb = testEnv.authenticatedContext("guest_uid").firestore();
    await assertFails(
      setDoc(doc(guestDb, `organizations/${dojoId}/members/guest_uid`), {
        role: "viewer",
        accessScope: "dojo",
        submittedJoinPinHash: hashJoinPin(dojoId, "wrong_pin"),
      })
    );

    // 正しい入室PINのみでAdminに昇格しようとする行為は拒否
    await assertFails(
      setDoc(doc(guestDb, `organizations/${dojoId}/members/guest_uid`), {
        role: "admin",
        accessScope: "dojo",
        submittedJoinPinHash: joinHash,
        submittedRolePinHash: hashRolePin(dojoId, "admin", "0000"),
      })
    );

    // 正しい入室PIN＋Admin PINでAdmin昇格成功
    await assertSucceeds(
      setDoc(doc(guestDb, `organizations/${dojoId}/members/guest_uid`), {
        role: "admin",
        accessScope: "dojo",
        submittedJoinPinHash: joinHash,
        submittedRolePinHash: adminHash,
      })
    );
  });

  test("private/admin_vault は Admin のみ閲覧・更新でき、Operator/Viewer からは遮断される", async () => {
    const { joinHash, adminHash, operatorHash } = await seedProtectedDojo("dojo_v");

    const opDb = testEnv.authenticatedContext("op_uid").firestore();
    await assertSucceeds(
      setDoc(doc(opDb, "organizations/dojo_v/members/op_uid"), {
        role: "operator",
        accessScope: "dojo",
        submittedJoinPinHash: joinHash,
        submittedRolePinHash: operatorHash,
      })
    );
    await assertFails(
      getDoc(doc(opDb, "organizations/dojo_v/private/admin_vault"))
    );
    await assertFails(
      setDoc(doc(opDb, "organizations/dojo_v/private/admin_vault"), {
        ciphertext: "tampered",
      })
    );

    const adminDb = testEnv.authenticatedContext("admin_uid").firestore();
    await assertSucceeds(
      setDoc(doc(adminDb, "organizations/dojo_v/members/admin_uid"), {
        role: "admin",
        accessScope: "dojo",
        submittedJoinPinHash: joinHash,
        submittedRolePinHash: adminHash,
      })
    );
    await assertSucceeds(
      getDoc(doc(adminDb, "organizations/dojo_v/private/admin_vault"))
    );

    // 誤った submittedCurrentAdminPinHash での更新は拒否
    await assertFails(
      updateDoc(doc(adminDb, "organizations/dojo_v/private/admin_vault"), {
        ciphertext: "v1:new",
        submittedCurrentAdminPinHash: hashRolePin("dojo_v", "admin", "0000"),
      })
    );

    // 正しい submittedCurrentAdminPinHash なら security と admin_vault を同時更新可能
    const newAdminHash = hashRolePin("dojo_v", "admin", "5555");
    const updateBatch = writeBatch(adminDb);
    updateBatch.update(doc(adminDb, "organizations/dojo_v/private/security"), {
      "rolePinHashes.admin": newAdminHash,
      submittedCurrentAdminPinHash: adminHash,
    });
    updateBatch.set(
      doc(adminDb, "organizations/dojo_v/private/admin_vault"),
      {
        ciphertext: "v1:reencrypted",
        version: 1,
        submittedCurrentAdminPinHash: adminHash,
      },
      { merge: true }
    );
    await assertSucceeds(updateBatch.commit());
  });

  test("private/owners は最大5名制限とアクセス隔離を守り、登録済み代表者のみPIN初期化できる", async () => {
    const { joinHash, adminHash } = await seedProtectedDojo("univ_dojo");

    const adminDb = testEnv.authenticatedContext("admin_uid").firestore();
    await assertSucceeds(
      setDoc(doc(adminDb, "organizations/univ_dojo/members/admin_uid"), {
        role: "admin",
        accessScope: "dojo",
        submittedJoinPinHash: joinHash,
        submittedRolePinHash: adminHash,
      })
    );

    // 6名登録は Rules 側でも拒否
    await assertFails(
      setDoc(doc(adminDb, "organizations/univ_dojo/private/owners"), {
        ownerEmails: [
          "a1@example.com",
          "a2@example.com",
          "a3@example.com",
          "a4@example.com",
          "a5@example.com",
          "a6@example.com",
        ],
        submittedCurrentAdminPinHash: adminHash,
      })
    );

    // 5名以内（代表者登録）は成功
    await assertSucceeds(
      setDoc(doc(adminDb, "organizations/univ_dojo/private/owners"), {
        ownerEmails: ["captain@example.com", "coach@example.com"],
        submittedCurrentAdminPinHash: adminHash,
      })
    );

    // 未登録ユーザー・email_verified=false のユーザーは private/owners を読めない
    const strangerDb = testEnv
      .authenticatedContext("stranger_uid", {
        email: "stranger@example.com",
        email_verified: true,
      })
      .firestore();
    await assertFails(
      getDoc(doc(strangerDb, "organizations/univ_dojo/private/owners"))
    );

    const unverifiedDb = testEnv
      .authenticatedContext("unverified_uid", {
        email: "captain@example.com",
        email_verified: false,
      })
      .firestore();
    await assertFails(
      getDoc(doc(unverifiedDb, "organizations/univ_dojo/private/owners"))
    );

    // 登録済み代表者は大文字小文字が異なるトークンメールでも読み取り＆PINリセットバッチ成功
    const ownerDb = testEnv
      .authenticatedContext("recovery_owner_uid", {
        email: "Captain@Example.com",
        email_verified: true,
      })
      .firestore();
    await assertSucceeds(
      getDoc(doc(ownerDb, "organizations/univ_dojo/private/owners"))
    );

    const resetJoinHash = hashJoinPin("univ_dojo", "reset2027");
    const resetAdminHash = hashRolePin("univ_dojo", "admin", "1234");
    const resetBatch = writeBatch(ownerDb);
    resetBatch.update(doc(ownerDb, "organizations/univ_dojo/private/security"), {
      joinPinHash: resetJoinHash,
      rolePinHashes: {
        admin: resetAdminHash,
        operator: hashRolePin("univ_dojo", "operator", "2468"),
        recorder: hashRolePin("univ_dojo", "recorder", "1357"),
      },
    });
    resetBatch.set(
      doc(ownerDb, "organizations/univ_dojo/private/admin_vault"),
      { ciphertext: "v1:recovered", version: 1 },
      { merge: true }
    );
    resetBatch.set(
      doc(ownerDb, "organizations/univ_dojo"),
      { rolePinPromptCompleted: true },
      { merge: true }
    );
    resetBatch.set(
      doc(ownerDb, "organizations/univ_dojo/members/recovery_owner_uid"),
      {
        role: "admin",
        accessScope: "dojo",
        submittedJoinPinHash: resetJoinHash,
        submittedRolePinHash: resetAdminHash,
      },
      { merge: true }
    );
    await assertSucceeds(resetBatch.commit());

    // 偽ハッシュを混ぜた復旧バッチは getAfter 検証で拒否される
    const fakeBatch = writeBatch(ownerDb);
    fakeBatch.update(doc(ownerDb, "organizations/univ_dojo/private/security"), {
      joinPinHash: resetJoinHash,
    });
    fakeBatch.set(
      doc(ownerDb, "organizations/univ_dojo/members/recovery_owner_uid"),
      {
        role: "viewer",
        accessScope: "dojo",
        submittedJoinPinHash: "mismatched_hash",
      },
      { merge: true }
    );
    await assertFails(fakeBatch.commit());
  });

  test("1大会限定 share_link の閲覧スコープが他大会および private ドキュメントから隔離される", async () => {
    await seedProtectedDojo("share_dojo");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, "organizations/share_dojo/share_links/tok_123"), {
        tournamentId: "tourney_1",
        isRevoked: false,
        expiresAt: null,
      });
    });

    const viewerDb = testEnv.authenticatedContext("scoped_viewer").firestore();
    await assertSucceeds(
      setDoc(doc(viewerDb, "organizations/share_dojo/members/scoped_viewer"), {
        role: "viewer",
        accessScope: "share_link",
        shareToken: "tok_123",
        sharedTournamentId: "tourney_1",
      })
    );
    await assertSucceeds(
      getDoc(doc(viewerDb, "organizations/share_dojo/tournaments/tourney_1"))
    );
    await assertFails(
      getDoc(doc(viewerDb, "organizations/share_dojo/tournaments/tourney_2"))
    );
    await assertFails(
      getDoc(doc(viewerDb, "organizations/share_dojo/private/owners"))
    );
  });
});

