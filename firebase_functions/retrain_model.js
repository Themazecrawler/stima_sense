const functions = require('firebase-functions');
const admin = require('firebase-admin');
const tf = require('@tensorflow/tfjs-node');

admin.initializeApp();

// Cloud Function to retrain the ML model
exports.retrainModel = functions.firestore
  .document('ml_training/training_job')
  .onCreate(async (snap, context) => {
    const trainingJob = snap.data();
    
    if (trainingJob.status !== 'triggered') {
      return null;
    }
    
    try {
      console.log('Starting model retraining...');
      
      // Update status to training
      await snap.ref.update({
        status: 'training',
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // 1. Get training data from Firestore
      const trainingData = await getTrainingData();
      
      // 2. Preprocess data
      const { features, labels } = preprocessData(trainingData);
      
      // 3. Create and train model
      const model = await trainModel(features, labels, trainingJob.trainingConfig);
      
      // 4. Evaluate model
      const evaluation = await evaluateModel(model, features, labels);
      
      // 5. Save model to Firebase ML Model Downloader
      await saveModelToFirebase(model, evaluation);
      
      // 6. Update training job status
      await snap.ref.update({
        status: 'completed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        evaluation: evaluation,
        modelVersion: Date.now().toString(),
      });
      
      console.log('Model retraining completed successfully');
      return null;
      
    } catch (error) {
      console.error('Error during retraining:', error);
      
      await snap.ref.update({
        status: 'failed',
        error: error.message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    }
  });

// Get training data from Firestore
async function getTrainingData() {
  const datasetDoc = await admin.firestore()
    .collection('ml_training')
    .doc('latest_dataset')
    .get();
  
  if (!datasetDoc.exists) {
    throw new Error('No training data available');
  }
  
  return datasetDoc.data().data;
}

// Preprocess data for training
function preprocessData(trainingData) {
  const features = [];
  const labels = [];
  
  // Process reports data
  trainingData.reports.forEach(report => {
    const feature = [
      new Date(report.timestamp).getMonth() / 12.0, // Event Month (normalized)
      new Date(report.timestamp).getHours() / 24.0, // Event Hour (normalized)
      (report.duration || 2.0) / 24.0, // Duration (normalized)
    ];
    
    features.push(feature);
    
    // Create label based on report severity
    const severity = report.severity || 'medium';
    const label = severity === 'critical' ? 3 : 
                  severity === 'high' ? 2 : 
                  severity === 'medium' ? 1 : 0;
    
    labels.push(label);
  });
  
  return {
    features: tf.tensor2d(features),
    labels: tf.tensor1d(labels, 'int32'),
  };
}

// Train the model
async function trainModel(features, labels, config) {
  // Create model architecture
  const model = tf.sequential({
    layers: [
      tf.layers.dense({
        units: 64,
        activation: 'relu',
        inputShape: [3], // Event Month, Event Hour, Duration
      }),
      tf.layers.dropout({ rate: 0.2 }),
      tf.layers.dense({
        units: 32,
        activation: 'relu',
      }),
      tf.layers.dropout({ rate: 0.2 }),
      tf.layers.dense({
        units: 4, // 4 classes: Low, Medium, High, Critical
        activation: 'softmax',
      }),
    ],
  });
  
  // Compile model
  model.compile({
    optimizer: tf.train.adam(config.learningRate || 0.001),
    loss: 'sparseCategoricalCrossentropy',
    metrics: ['accuracy'],
  });
  
  // Train model
  await model.fit(features, labels, {
    epochs: config.epochs || 100,
    batchSize: config.batchSize || 32,
    validationSplit: config.validationSplit || 0.2,
    callbacks: [
      tf.callbacks.earlyStopping({ patience: 10 }),
    ],
  });
  
  return model;
}

// Evaluate the model
async function evaluateModel(model, features, labels) {
  const evaluation = await model.evaluate(features, labels);
  const accuracy = await evaluation[1].data();
  
  return {
    accuracy: accuracy[0],
    loss: (await evaluation[0].data())[0],
  };
}

// Save model to Firebase ML Model Downloader
async function saveModelToFirebase(model, evaluation) {
  // Convert model to TFLite format
  const tfliteModel = await tf.io.convertTensorFlowModel(model);
  
  // Save to Firebase Storage (you'll need to implement this)
  // This is a placeholder - you'll need to implement the actual upload
  console.log('Model evaluation:', evaluation);
  console.log('Model ready for upload to Firebase ML Model Downloader');
  
  // TODO: Implement actual model upload to Firebase ML Model Downloader
  // This would involve:
  // 1. Converting to TFLite format
  // 2. Uploading to Firebase Storage
  // 3. Registering with Firebase ML Model Downloader
}

// Scheduled function for automatic retraining
exports.scheduledRetraining = functions.pubsub
  .schedule('0 2 * * 0') // Every Sunday at 2 AM
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      console.log('Running scheduled retraining...');
      
      // Check if retraining is due
      const scheduleDoc = await admin.firestore()
        .collection('ml_config')
        .doc('retraining_schedule')
        .get();
      
      if (!scheduleDoc.exists) {
        console.log('No retraining schedule configured');
        return null;
      }
      
      const schedule = scheduleDoc.data();
      if (!schedule.enabled) {
        console.log('Retraining is disabled');
        return null;
      }
      
      // Trigger retraining
      await admin.firestore()
        .collection('ml_training')
        .doc('training_job')
        .set({
          status: 'triggered',
          triggeredAt: admin.firestore.FieldValue.serverTimestamp(),
          modelName: 'outage_model',
          trainingConfig: {
            epochs: 100,
            batchSize: 32,
            learningRate: 0.001,
            validationSplit: 0.2,
          },
        });
      
      console.log('Scheduled retraining triggered');
      return null;
      
    } catch (error) {
      console.error('Error in scheduled retraining:', error);
      return null;
    }
  }); 