<script>
    import QuestionToolbar from "./QuestionToolbar.svelte";
    import ExplanationPanel from "./ExplanationPanel.svelte";
    import TextArea from "../TextArea.svelte";

    let {
        data,
        userAnswer = null,
        submitAnswer,
        clearAnswer,
        questionNumber,
    } = $props();

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

    function handleClearAnswer() {
        clearAnswer();
    }
</script>

<div class="space-y-4">
    <!-- Question Toolbar -->
    <QuestionToolbar
        {questionNumber}
        difficulty={data.difficulty}
        retentionAid={data.retention_aid}
        hasExplanation={!!data.explanation}
        {isAnswered}
        bind:showExplanation
        onclearAnswer={handleClearAnswer}
    >
        {#if data.explanation}
            <ExplanationPanel explanation={data.explanation} />
        {/if}
    </QuestionToolbar>

    <!-- Question Text -->
    <div class="text-lg font-medium text-base-content leading-relaxed">
        {data.question_text}
    </div>

    <!-- Answer Input -->
    <div class="space-y-3">
        <label for="answer-text" class="text-sm font-medium text-base-content"
            >Your Answer:</label
        >
        <TextArea
            value={answerText}
            oninput={handleAnswerChange}
            placeholder="Type your answer here..."
            disabled={isAnswered}
            rows={6}
            class="w-full"
        />
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
</div>
