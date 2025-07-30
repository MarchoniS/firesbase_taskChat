const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// Notify assigned user when task is assigned
exports.sendTaskAssignedNotification = functions.firestore
    .document("tasks/{taskId}")
    .onCreate(async (snap, context) => {
      const task = snap.data();
      const assignedTo = task.assignedTo;

      if (!assignedTo) return null;

      const userDoc = await db.collection("users").doc(assignedTo).get();
      const userData = userDoc.data();
      const fcmToken = userData && userData.fcmToken;

      if (fcmToken) {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: "New Task Assigned",
            body: `Task: ${task.title || "No Title"} has been assigned to you.`,
          },
        });
      }

      return null;
    });

// Notify assigner when task is marked completed
exports.sendTaskCompletedNotification = functions.firestore
    .document("tasks/{taskId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      if (before.status === "completed" || after.status !== "completed") {
        return null;
      }

      const assignedBy = after.assignedBy;

      if (!assignedBy) return null;

      const userDoc = await db.collection("users").doc(assignedBy).get();
      const userData = userDoc.data();
      const fcmToken = userData && userData.fcmToken;

      if (fcmToken) {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: "Task Completed",
            body: `Task: ${after.title || "No Title"} has been completed.`,
          },
        });
      }

      return null;
    });

// Notify user on new chat message
exports.sendNewChatNotification = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const message = snap.data();
      const receiverId = message.receiverId;

      if (!receiverId) return null;

      const userDoc = await db.collection("users").doc(receiverId).get();
      const userData = userDoc.data();
      const fcmToken = userData && userData.fcmToken;

      if (fcmToken) {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: `New message from ${message.senderName || "Unknown"}`,
            body: message.text || "You received a new message",
          },
        });
      }

      return null;
    });
