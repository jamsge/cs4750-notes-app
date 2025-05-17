import { onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import axios from "axios";

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

// Configure Firestore Emulator if in testing environment
if (process.env.NODE_ENV === "test") {
    console.log("conencting to emulator...");
    //Optional: configure settings for emulator
    db.settings({
        host: "localhost:8080",
        ssl: false,
        ignoreUndefinedProperties: true,
    });
}

// Deepseek API configuration
const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY;
const DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions";

/**
 * Generate a summary of document content using DeepSeek's API
 */
export const generateSummary = onCall(async (request) => {
  try {
    
    const userUid = request.auth?.uid;
    // Extract document path from request data
    const docPath = "userData/" + userUid + "/" + request.data.docPath;
    if (!docPath) {
      throw new Error("Document path is required");
    }

    // Get the document from Firestore
    const docRef = db.doc(docPath);
    const docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      throw new Error(`Document not found at path: ${docPath}`);
    }

    const data = docSnapshot.data();
    if (!data?.content || typeof data.content !== "string") {
      throw new Error("Document doesn't contain a valid 'content' field");
    }

    // Call DeepSeek API to generate summary
    const response = await axios.post(
      DEEPSEEK_API_URL,
      {
        model: "deepseek-chat",
        messages: [
          {
            role: "system",
            content: "You are a helpful assistant that creates concise summaries of text content."
          },
          {
            role: "user",
            content: `Please provide a concise summary of the following text: ${data.content}`
          }
        ],
        max_tokens: 500
      },
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${DEEPSEEK_API_KEY}`
        }
      }
    );

    // Extract the summary from the response
    const summary = response.data.choices[0].message.content;

    // Store the summary back to the document
    await docRef.update({
      summary: summary,
      summaryCreatedAt: new Date()
    });

    logger.info(`Summary generated for document: ${docPath}`);
    
    return { 
      success: true, 
      summary: summary 
    };
  } catch (error) {
    let errorMessage = "An unknown error occurred";
    if (error instanceof Error) {
      errorMessage = error.message;
    }
    logger.error("Error generating summary:", errorMessage);
    throw new Error(`Failed to generate summary: ${errorMessage}`);
  }
});

/**
 * Generate flashcards from document content using DeepSeek's API
 */
export const generateFlashcards = onCall(async (request) => {
  try {
    const userUid = request.auth?.uid;
    // Extract document path from request data
    const docPath = "userData/" + userUid + "/" + request.data.docPath;
    if (!docPath) {
      throw new Error("Document path is required");
    }

    // Get the document from Firestore
    const docRef = db.doc(docPath);
    const docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      throw new Error(`Document not found at path: ${docPath}`);
    }

    const data = docSnapshot.data();
    if (!data?.content || typeof data.content !== "string") {
      throw new Error("Document doesn't contain a valid 'content' field");
    }

    // Call DeepSeek API to generate flashcards
    const response = await axios.post(
      DEEPSEEK_API_URL,
      {
        model: "deepseek-chat",
        messages: [
          {
            role: "system",
            content: "You are a helpful assistant that extracts key concepts and their definitions from text content in a format suitable for flashcards. Output should be in the format of 'concept \\t definition' with each flashcard on a new line." +
            "ONLY REPLY WITH 'concept \\t definition' formatting, do not add any other dialogue."
          },
          {
            role: "user",
            content: `Please extract key concepts and their definitions from the following text in the format 'concept \\t definition' with each flashcard on a new line: ${data.content}`
          }
        ],
        max_tokens: 2000
      },
      {
        headers: {
          "Content-Type": "application/json", 
          "Authorization": `Bearer ${DEEPSEEK_API_KEY}`
        }
      }
    );

    // Extract the flashcards from the response
    const flashcardsText = response.data.choices[0].message.content;

    // Store the flashcards back to the document
    await docRef.update({
      flashcards: flashcardsText,
      flashcardsCreatedAt: new Date()
    });

    logger.info(`Flashcards generated for document: ${docPath}`);
    
    return { 
      success: true, 
      flashcards: flashcardsText 
    };
  } catch (error) {
    let errorMessage = "An unknown error occurred";
    if (error instanceof Error) {
      errorMessage = error.message;
    }
    logger.error("Error generating flashcards:", errorMessage);
    throw new Error(`Failed to generate flashcards: ${errorMessage}`);
  }
});
