/**
 * Utility functions for handling cloze questions
 */

/**
 * Parse cloze text and extract cloze data
 * @param {string} text - The cloze text containing {{c1::answer::hint}} patterns
 * @returns {Object} Object with clozes array and processedText
 */
export function parseClozeText(text) {
    if (!text) return { clozes: [], processedText: text };
    
    const clozePattern = /\{\{c(\d+)::([^:}]+)(?:::([^}]*))?\}\}/g;
    const clozes = [];
    let processedText = text;
    let match;
    let replacementIndex = 0;
    
    while ((match = clozePattern.exec(text)) !== null) {
        const [fullMatch, clozeNumber, answer, hint] = match;
        const clozeId = parseInt(clozeNumber);
        
        clozes.push({
            id: clozeId,
            answer: answer.trim(),
            hint: hint ? hint.trim() : '',
            placeholder: `[CLOZE_${replacementIndex}]`
        });
        
        processedText = processedText.replace(fullMatch, `[CLOZE_${replacementIndex}]`);
        replacementIndex++;
    }
    
    return { clozes, processedText };
}

/**
 * Format cloze text for display, replacing placeholders with blanks or answers
 * @param {string} text - The cloze text
 * @param {boolean} showAnswers - Whether to show answers (true) or blanks (false)
 * @returns {string} Formatted text for display
 */
export function formatClozeForDisplay(text, showAnswers = false) {
    if (!text) return text;
    
    const { clozes, processedText } = parseClozeText(text);
    let displayText = processedText;
    
    clozes.forEach((cloze, index) => {
        const placeholder = `[CLOZE_${index}]`;
        if (showAnswers) {
            displayText = displayText.replace(placeholder, cloze.answer);
        } else {
            // Create a beautiful blank with underscores based on answer length
            const blankLength = Math.max(3, cloze.answer.length);
            const blank = '_'.repeat(blankLength);
            displayText = displayText.replace(placeholder, `[${blank}]`);
        }
    });
    
    return displayText;
}

/**
 * Extract a readable preview from cloze text (used for search/display)
 * @param {string} text - The cloze text
 * @returns {string} Clean text with hints or blanks
 */
export function extractClozePreview(text) {
    return formatClozeForDisplay(text, false);
} 