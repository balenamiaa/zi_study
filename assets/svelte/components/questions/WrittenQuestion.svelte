<script>
        import MarkdownContent from "../MarkdownContent.svelte";
    
    let { data, userAnswer = null, submitAnswer, clearAnswer } = $props();
    
    let answerText = $state(userAnswer?.data?.answer_text || "");
    let showExplanation = $state(false);
    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);

    function handleSubmitAnswer() {
        if (answerText.trim()) {
            submitAnswer({
                answer_text: answerText,
            });
        }
    }

    function handleAnswerChange(event) {
        if (!isAnswered) {
            answerText = event.target.value;
        }
    }
</script>

<div class="space-y-4">
    <!-- Question Text -->
    <div class="text-lg font-medium text-base-content leading-relaxed">
        {data.question_text}
    </div>

    <!-- Answer Input -->
    <div class="space-y-3">
        <label class="text-sm font-medium text-base-content">Your Answer:</label
        >
        <textarea
            value={answerText}
            oninput={handleAnswerChange}
            placeholder="Type your answer here..."
            class="textarea textarea-bordered w-full h-32 resize-none"
            disabled={isAnswered}
        ></textarea>
    </div>

    <!-- Action Buttons -->
    {#if !isAnswered}
        <div class="flex gap-2">
            <button
                class="btn btn-primary btn-sm"
                onclick={handleSubmitAnswer}
                disabled={!answerText.trim()}
            >
                Submit Answer
            </button>
        </div>
    {/if}

    <!-- Answer Display -->
    {#if isAnswered}
        <div class="space-y-4">
            <!-- User's Answer -->
            <div class="p-4 bg-base-100 border border-base-300 rounded-lg">
                <div class="flex items-start gap-2 mb-2">
                    <svg
                        class="w-4 h-4 text-primary mt-1"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                        />
                    </svg>
                    <div class="text-sm font-medium text-primary">
                        Your Answer
                    </div>
                </div>
                <div class="text-sm text-base-content pl-6 whitespace-pre-wrap">
                    {answerText}
                </div>
            </div>

            <!-- Correct Answer -->
            {#if data.correct_answer}
                <div
                    class="p-4 bg-success/10 border border-success/20 rounded-lg"
                >
                    <div class="flex items-start gap-2 mb-2">
                        <svg
                            class="w-4 h-4 text-success mt-1"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                            />
                        </svg>
                        <div class="text-sm font-medium text-success">
                            Model Answer
                        </div>
                    </div>
                    <div
                        class="text-sm text-base-content pl-6 whitespace-pre-wrap"
                    >
                        {data.correct_answer}
                    </div>
                </div>
            {/if}

            <!-- Note about manual grading -->
            <div class="p-3 bg-warning/10 border border-warning/20 rounded-lg">
                <div class="flex items-start gap-2">
                    <svg
                        class="w-4 h-4 text-warning mt-0.5"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                    </svg>
                    <div class="text-sm text-warning">
                        <div class="font-medium">Manual Review Required</div>
                        <div class="text-base-content/70 mt-1">
                            This written answer requires manual grading. Compare
                            your response with the model answer above.
                        </div>
                    </div>
                </div>
            </div>
        </div>
    {/if}

    {#if isAnswered}
        <div class="flex justify-end gap-2 mt-4">
            {#if data.explanation}
                <button
                    class="btn btn-ghost btn-xs"
                    onclick={() => (showExplanation = !showExplanation)}
                    title="Toggle Explanation"
                >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                </button>
            {/if}
            <button
                class="btn btn-ghost btn-xs text-error"
                onclick={clearAnswer}
                title="Clear Answer"
            >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
            </button>
        </div>
    {/if}

    {#if showExplanation && data.explanation}
        <div class="mt-3 p-3 bg-base-100 border border-base-300 rounded-lg">
            <div class="flex items-start gap-2">
                <svg class="w-4 h-4 text-info mt-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <div>
                    <div class="text-xs font-medium text-info uppercase tracking-wide">Explanation</div>
                    <MarkdownContent content={data.explanation} cssClass="text-sm text-base-content mt-1 prose prose-sm max-w-none" />
                </div>
            </div>
        </div>
    {/if}
</div>
