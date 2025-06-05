<script>
    import QuestionToolbar from "./QuestionToolbar.svelte";
    import ExplanationPanel from "./ExplanationPanel.svelte";
    import RadioWithSpinner from "./RadioWithSpinner.svelte";

    let {
        data,
        userAnswer = null,
        submitAnswer,
        clearAnswer,
        questionNumber,
        live,
        questionId = null,
        userQuestionSets = null,
    } = $props();

    let selectedOption = $state(userAnswer?.data?.selected_index ?? null);
    let showExplanation = $state(false);
    let isSubmitting = $state(false);
    let answerSubmittedHandleRef = $state(null);
    let answerResetHandleRef = $state(null);

    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);

    function handleOptionSelect(index) {
        if (!isAnswered && !isSubmitting) {
            selectedOption = index;
            isSubmitting = true;
            submitAnswer({
                selected_index: index,
            });
        }
    }

    function handleClearAnswer() {
        clearAnswer();
    }

    function handleAnswerSubmitted() {
        isSubmitting = false;
    }

    function handleAnswerReset(payload) {
        const eventQuestionId = payload.question_id;
        const currentQuestionId =
            data?.id?.toString() || questionNumber?.toString();
        if (eventQuestionId === currentQuestionId) {
            selectedOption = null;
            isSubmitting = false;
        }
    }

    $effect(() => {
        if (live) {
            answerSubmittedHandleRef = live.handleEvent(
                "answer_submitted",
                handleAnswerSubmitted,
            );
            answerResetHandleRef = live.handleEvent(
                "answer_reset",
                handleAnswerReset,
            );

            return () => {
                if (live) {
                    live.removeHandleEvent(answerSubmittedHandleRef);
                    live.removeHandleEvent(answerResetHandleRef);
                }
            };
        }
    });
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
        {questionId}
        {live}
        {userQuestionSets}
    >
        {#if data.explanation && isAnswered}
            <ExplanationPanel explanation={data.explanation} />
        {/if}
    </QuestionToolbar>

    <!-- Question Text -->
    <div class="text-lg font-medium text-base-content leading-relaxed">
        {data.question_text}
    </div>

    <!-- Options -->
    <div class="space-y-3">
        {#each data.options as option, index}
            {@const isSelected = selectedOption === index}
            {@const isCorrect = isAnswered && userAnswer?.is_correct === 1}
            {@const isIncorrect = isAnswered && userAnswer?.is_correct === 0}
            {@const isCorrectOption =
                isAnswered && index === data.correct_index}
            {@const showAsCorrect = isAnswered && isCorrectOption}
            {@const showAsIncorrect =
                isAnswered && isSelected && !isCorrectOption}

            <label
                class="flex items-start gap-3 p-3 rounded-lg border transition-all duration-200 {showAsCorrect
                    ? 'border-success bg-success/10'
                    : showAsIncorrect
                      ? 'border-error bg-error/10'
                      : isSelected
                        ? 'border-primary bg-primary/5'
                        : isAnswered || isSubmitting
                          ? 'border-base-300'
                          : 'border-base-300 hover:border-primary/50 cursor-pointer hover:bg-base-100'} {isAnswered ||
                isSubmitting
                    ? 'cursor-default'
                    : 'cursor-pointer'}"
            >
                <RadioWithSpinner
                    name="mcq-single-option-{questionNumber}"
                    value={index}
                    checked={isSelected}
                    onchange={() => handleOptionSelect(index)}
                    disabled={isAnswered || isSubmitting}
                    showSpinner={isSubmitting && isSelected}
                    variant={showAsCorrect
                        ? "success"
                        : showAsIncorrect
                          ? "error"
                          : "primary"}
                />
                <div class="flex-1">
                    <span
                        class="text-base-content {showAsCorrect
                            ? 'text-success font-medium'
                            : showAsIncorrect
                              ? 'text-error'
                              : ''}">{option}</span
                    >
                    {#if showAsCorrect}
                        <div class="flex items-center gap-1 mt-1">
                            <svg
                                class="w-4 h-4 text-success"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M5 13l4 4L19 7"
                                />
                            </svg>
                            <span class="text-xs text-success font-medium"
                                >Correct</span
                            >
                        </div>
                    {:else if showAsIncorrect}
                        <div class="flex items-center gap-1 mt-1">
                            <svg
                                class="w-4 h-4 text-error"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                            <span class="text-xs text-error font-medium"
                                >Your answer</span
                            >
                        </div>
                    {/if}
                </div>
            </label>
        {/each}
    </div>

    {#if isAnswered && userAnswer?.is_correct === 0}
        <div class="p-3 bg-info/10 border border-info/20 rounded-lg">
            <div class="flex items-center gap-2">
                <svg
                    class="w-4 h-4 text-info"
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
                <span class="text-sm font-medium text-info"
                    >The correct answer is highlighted above</span
                >
            </div>
        </div>
    {/if}
</div>
