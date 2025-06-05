/**
 * Shared utilities for question components
 */

/**
 * Creates a standardized live event handler setup for question components
 * @param {Object} live - Phoenix LiveView socket
 * @param {Function} onAnswerSubmitted - Callback when answer is submitted
 * @param {Function} onAnswerReset - Callback when answer is reset
 * @returns {Function} Cleanup function
 */
export function setupQuestionEvents(live, onAnswerSubmitted, onAnswerReset) {
    if (!live) return () => {};

    const answerSubmittedHandle = live.handleEvent("answer_submitted", onAnswerSubmitted);
    const answerResetHandle = live.handleEvent("answer_reset", onAnswerReset);

    return () => {
        if (live) {
            live.removeHandleEvent(answerSubmittedHandle);
            live.removeHandleEvent(answerResetHandle);
        }
    };
}

/**
 * Creates a standardized answer reset handler
 * @param {Object} data - Question data
 * @param {number} questionNumber - Question number
 * @param {Function} resetCallback - Function to call to reset the answer
 * @returns {Function} Answer reset handler
 */
export function createAnswerResetHandler(data, questionNumber, resetCallback) {
    return (payload) => {
        const eventQuestionId = payload.question_id;
        const currentQuestionId = data?.id?.toString() || questionNumber?.toString();
        
        if (eventQuestionId === currentQuestionId) {
            resetCallback();
        }
    };
}

/**
 * Validates if all required fields are filled for submission
 * @param {Array|Object} answer - The answer data to validate
 * @param {string} type - Type of question ('single', 'multi', 'text', 'cloze', 'emq')
 * @returns {boolean} Whether the answer is valid for submission
 */
export function isAnswerValid(answer, type) {
    switch (type) {
        case 'single':
            return answer !== null && answer !== undefined;
        case 'multi':
            return Array.isArray(answer) && answer.length > 0;
        case 'text':
            return typeof answer === 'string' && answer.trim().length > 0;
        case 'cloze':
            return Array.isArray(answer) && answer.every(a => a.trim() !== '');
        case 'emq':
            return Array.isArray(answer) && answer.length > 0;
        default:
            return false;
    }
}

/**
 * Creates standardized submission handler with loading state
 * @param {Function} submitAnswer - Function to submit the answer
 * @param {Function} setIsSubmitting - Function to set loading state
 * @returns {Function} Submission handler
 */
export function createSubmissionHandler(submitAnswer, setIsSubmitting) {
    return (answerData) => {
        setIsSubmitting(true);
        submitAnswer(answerData);
    };
} 