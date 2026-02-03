const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/* ============================
   ADMIN: CREATE USER
============================ */
exports.adminCreateUser = onCall(async (request) => {
  // 1️⃣ Auth check
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in");
  }

  // 2️⃣ Check admin role
  const callerUid = request.auth.uid;

  const callerDoc = await getFirestore()
    .collection("users")
    .doc(callerUid)
    .get();

  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Only admins can create users"
    );
  }

  const { email, password, fullName, role } = request.data;

  if (!email || !password || !fullName || !role) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields"
    );
  }

  if (!["customer", "doctor", "admin"].includes(role)) {
    throw new HttpsError("invalid-argument", "Invalid role");
  }

  // 3️⃣ Create Auth user
  const userRecord = await getAuth().createUser({
    email,
    password,
    displayName: fullName,
  });

  const uid = userRecord.uid;

  // 4️⃣ Create Firestore user doc
  await getFirestore()
    .collection("users")
    .doc(uid)
    .set({
      fullName,
      email,
      role,
      doctorId: null,
      disabled: false,
      createdAt: new Date(),
    });

  return {
    success: true,
    uid,
  };
});

/* ============================
   ADMIN: CHANGE USER ROLE
============================ */
exports.adminChangeUserRole = onCall(async (request) => {
  const { uid, role } = request.data;

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const callerUid = request.auth.uid;

  const callerDoc = await getFirestore()
    .collection("users")
    .doc(callerUid)
    .get();

  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new HttpsError("permission-denied", "Admin only");
  }

  const allowedRoles = ["customer", "doctor", "admin"];
  if (!allowedRoles.includes(role)) {
    throw new HttpsError("invalid-argument", "Invalid role");
  }

  await getAuth().setCustomUserClaims(uid, { role });

  await getFirestore()
    .collection("users")
    .doc(uid)
    .update({
      role,
      updatedAt: new Date(),
    });

  return { success: true };
});

exports.adminToggleUserDisabled = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not logged in");
  }

  const callerUid = request.auth.uid;
  const { uid, disabled } = request.data;

  const callerDoc = await getFirestore()
    .collection("users")
    .doc(callerUid)
    .get();

  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new HttpsError("permission-denied", "Admin only");
  }

  // 🔒 Disable Firebase Auth login
  await getAuth().updateUser(uid, {
    disabled: disabled,
  });

  // 🗂 Sync Firestore
  await getFirestore()
    .collection("users")
    .doc(uid)
    .update({
      disabled,
      updatedAt: new Date(),
    });

  return { success: true };
});

exports.adminCreateDoctor = onCall(
  { region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    const callerUid = request.auth.uid;

    const callerDoc = await getFirestore()
      .collection("users")
      .doc(callerUid)
      .get();

    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new HttpsError("permission-denied", "Admin only");
    }

    const {
      fullName,
      email,
      experience,
      aboutMe,
      categoryId,
      categoryName,
      photoUrl,
    } = request.data;

    await getFirestore().collection("doctors").add({
      userId: null,
      name: fullName,
      email,
      experience,
      aboutMe,
      categoryId,
      categoryName,
      photoUrl,

      availability: {
        monday: [],
        tuesday: [],
        wednesday: [],
        thursday: [],
        friday: [],
        saturday: [],
        sunday: [],
      },

      available: false,     // ✅ ADD THIS
      activated: false,    // ❗ stays false until admin approves
      createdAt: new Date(),
    });

    return { success: true };
  }
);

exports.adminDeleteUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not logged in");
  }

  const callerUid = request.auth.uid;

  const callerDoc = await getFirestore()
    .collection("users")
    .doc(callerUid)
    .get();

  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new HttpsError("permission-denied", "Admin only");
  }

  const { uid } = request.data;

  if (!uid) {
    throw new HttpsError("invalid-argument", "Missing uid");
  }

  // 🧨 Delete Firestore user profile
  await getFirestore()
    .collection("users")
    .doc(uid)
    .delete();

  // 🔒 Delete Firebase Auth account
  await getAuth().deleteUser(uid);

  return { success: true };
});
