import assert from 'assert';
import admin from "firebase-admin"
import index from '../src/index';



// At the top of test/index.test.js
// Make sure to use values from your actual Firebase configuration
const fbFunctest = require('firebase-functions-test')({
  databaseURL: 'https://cs4750-project-9653f.firebaseio.com',
  storageBucket: 'cs4750-project-9653f.firebasestorage.app',
  projectId: 'cs4750-project-9653f',
}, './serviceAccountKey.json');

describe('Summary test', () => {
	it('should create a summary of note content', async () => {
		const db = admin.firestore();
    const docRef = db.collection("test").doc();
    
    await docRef.set({
      content: ""
    });
    
    console.log(`Document created successfully at test/${docRef.id}`);
		fbFunctest.wrap(index.generateSummary);
	});
});