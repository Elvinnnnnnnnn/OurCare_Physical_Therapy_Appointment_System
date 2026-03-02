const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
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
      consultationPrice,
      currency,
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

      consultationPrice: consultationPrice,
      currency: currency ?? "PHP",

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

/* ============================
   APPOINTMENT STATUS NOTIFICATION
============================ */
const db = getFirestore(); // ✅ REQUIRED

exports.onAppointmentStatusChange = onDocumentUpdated(
  {
    document: "appointments/{appointmentId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data.before?.data();
    const after = event.data.after?.data();

    if (!before || !after) return;
    if (before.status === after.status) return;

    if (!["approved", "cancelled"].includes(after.status)) return;

    const isApproved = after.status === "approved";

    const title = isApproved
      ? "Appointment Approved"
      : "Appointment Cancelled";

    const body = isApproved
      ? `Dr. ${after.doctorName} approved your appointment on ${after.date} at ${after.time}.`
      : `Dr. ${after.doctorName} cancelled your appointment scheduled on ${after.date}.`;

    await db.collection("notifications").add({
      userId: after.userId,
      title,
      body,
      read: false,
      type: "appointment_status",
      appointmentId: event.params.appointmentId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("✅ Status notification created");
  }
);

const { getMessaging } = require("firebase-admin/messaging");

/* ============================
   PUSH: APPOINTMENT APPROVED
============================ */
exports.pushOnAppointmentApproved = onDocumentUpdated(
  {
    document: "appointments/{appointmentId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data.before?.data();
    const after = event.data.after?.data();

    if (!before || !after) return;

    // Only trigger when status changes TO approved
    if (before.status === after.status) return;
    if (after.status !== "approved") return;

    // Get patient FCM token
    const userDoc = await db
      .collection("users")
      .doc(after.userId)
      .get();

    const token = userDoc.data()?.fcmToken;

    if (!token) {
      console.log("No FCM token found");
      return;
    }

    await getMessaging().send({
      token: token,
      notification: {
        title: "Appointment Approved",
        body: `Dr. ${after.doctorName} approved your appointment on ${after.date} at ${after.time}.`,
      },
      data: {
        type: "appointment_status",
        appointmentId: event.params.appointmentId,
      },
    });

    console.log("Push notification sent");
  }
);

const { onSchedule } =
  require("firebase-functions/v2/scheduler");

exports.sendAppointmentReminders = onSchedule(
  {
    schedule: "every 1 minutes",
    region: "us-central1",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    const twoMinutesAgo = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 2 * 60 * 1000
    );

    const snapshot = await db
      .collection("appointments")
      .where("status", "==", "approved")
      .where("reminderSent", "==", false)
      .where("appointmentAt", "<=", twoMinutesAgo)
      .get();

    if (snapshot.empty) return;

    const batch = db.batch();

    for (const doc of snapshot.docs) {
      const appt = doc.data();

      const notifRef = db.collection("notifications").doc();
      batch.set(notifRef, {
        userId: appt.userId,
        title: "Appointment Reminder",
        body: `Your appointment with Dr. ${appt.doctorName} has started.`,
        read: false,
        type: "appointment_reminder",
        appointmentId: doc.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      batch.update(doc.ref, {
        reminderSent: true,
      });
    }

    await batch.commit();
    console.log("⏰ Appointment reminders sent");
  }
);

