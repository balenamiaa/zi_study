<script>
    import QuestionToolbar from "./QuestionToolbar.svelte";
    import ExplanationPanel from "./ExplanationPanel.svelte";
    import { setupQuestionEvents, createAnswerResetHandler, createSubmissionHandler, isAnswerValid } from "../../utils/questionUtils.js";

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

    let selectedOptions = $state(userAnswer?.data?.selected_indices ?? []);
    let showExplanation = $state(false);
    let isSubmitting = $state(false);
    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);
    let canSubmit = $derived(isAnswerValid(selectedOptions, 'multi'));

    function handleOptionToggle(index) {
        if (!isAnswered && !isSubmitting) {
            if (selectedOptions.includes(index)) {
                selectedOptions = selectedOptions.filter((i) => i !== index);
            } else {
                selectedOptions = [...selectedOptions, index];
            }
        }
    }

    const handleSubmission = createSubmissionHandler(submitAnswer, (loading) => isSubmitting = loading);

    function checkAnswer() {
        if (canSubmit && !isSubmitting) {
            handleSubmission({
                selected_indices: selectedOptions,
            });
        }
    }

    function handleClearAnswer() {
        clearAnswer();
    }

    function handleAnswerSubmitted() {
        isSubmitting = false;
    }

    const handleAnswerReset = createAnswerResetHandler(data, questionNumber, () => {
        selectedOptions = [];
        isSubmitting = false;
    });

    $effect(() => {
        return setupQuestionEvents(live, handleAnswerSubmitted, handleAnswerReset);
    });
</script>

<div class="space-y-4">
    <QuestionToolbar
        {questionNumber}
        difficulty={data.difficulty}
        retentionAid={data.retention_aid}
        hasExplanation={!!data.explanation}
        {isAnswered}
        bind:showExplanation
        onClearAnswer={handleClearAnswer}
        {questionId}
        {live}
        {userQuestionSets}
    >
        {#if data.explanation && isAnswered}
            <ExplanationPanel explanation={data.explanation} />
        {/if}
    </QuestionToolbar>

    <div class="text-lg font-medium text-base-content leading-relaxed">
        {data.question_text}
    </div>

    <div class="space-y-3">
        {#each data.options as option, index}
            {@const isSelected = selectedOptions.includes(index)}
            {@const isCorrectOption =
                isAnswered && data.correct_indices.includes(index)}
            {@const isIncorrectSelection =
                isAnswered &&
                isSelected &&
                !data.correct_indices.includes(index)}
            {@const isMissedCorrect =
                isAnswered &&
                !isSelected &&
                data.correct_indices.includes(index)}

            <label
                class="flex items-start gap-3 p-3 rounded-lg border transition-all duration-200 {isCorrectOption &&
                isSelected
                    ? 'border-success bg-success/10'
                    : isIncorrectSelection
                      ? 'border-error bg-error/10'
                      : isMissedCorrect
                        ? 'border-warning bg-warning/10'
                        : isSelected
                          ? 'border-primary bg-primary/5'
                          : isAnswered || isSubmitting
                            ? 'border-base-300'
                            : 'border-base-300 hover:border-primary/50 cursor-pointer hover:bg-base-100'} {isAnswered ||
                isSubmitting
                    ? 'cursor-default'
                    : 'cursor-pointer'}"
            >
                <input
                    type="checkbox"
                    checked={isSelected}
                    onchange={() => handleOptionToggle(index)}
                    disabled={isAnswered || isSubmitting}
                    class="checkbox checkbox-primary mt-1 {isCorrectOption &&
                    isSelected
                        ? 'checkbox-success'
                        : isIncorrectSelection
                          ? 'checkbox-error'
                          : isMissedCorrect
                            ? 'checkbox-warning'
                            : ''}"
                />
                <div class="flex-1">
                    <div class="flex items-center justify-between">
                        <span
                            class="text-base-content {isCorrectOption &&
                            isSelected
                                ? 'text-success font-medium'
                                : isIncorrectSelection
                                  ? 'text-error'
                                  : isMissedCorrect
                                    ? 'text-warning'
                                    : ''}">{option}</span
                        >

                        {#if isAnswered}
                            <div class="flex items-center gap-1">
                                {#if isCorrectOption && isSelected}
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
                                    <span
                                        class="text-xs text-success font-medium"
                                        >Correct</span
                                    >
                                {:else if isIncorrectSelection}
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
                                        >Incorrect</span
                                    >
                                {:else if isMissedCorrect}
                                    <svg
                                        class="w-4 h-4 text-warning"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.232 15.5c-.77.833.192 2.5 1.732 2.5z"
                                        />
                                    </svg>
                                    <span
                                        class="text-xs text-warning font-medium"
                                        >Missed</span
                                    >
                                {/if}
                            </div>
                        {/if}
                    </div>
                </div>
            </label>
        {/each}
    </div>

    {#if !isAnswered}
        <div class="text-sm text-base-content/60 italic">
            Select all correct answers
        </div>
    {/if}

    {#if !isAnswered}
        <div class="flex gap-2">
            <button
                class="btn btn-primary btn-sm relative"
                onclick={checkAnswer}
                disabled={!canSubmit || isSubmitting}
            >
                {#if isSubmitting}
                    <span class="loading loading-spinner loading-xs"></span>
                    Checking...
                {:else}
                    Check Answer
                {/if}
            </button>
        </div>
    {/if}

    {#if isAnswered}
        {@const isCorrect = userAnswer?.is_correct === 1}
        {@const correctCount = selectedOptions.filter((i) =>
            data.correct_indices.includes(i),
        ).length}
        {@const incorrectCount = selectedOptions.filter(
            (i) => !data.correct_indices.includes(i),
        ).length}
        {@const missedCount = data.correct_indices.filter(
            (i) => !selectedOptions.includes(i),
        ).length}

        <div
            class="p-4 rounded-lg {isCorrect
                ? 'bg-success/10 border border-success/20'
                : 'bg-base-100 border border-base-300'}"
        >
            <div class="flex items-start gap-3">
                {#if isCorrect}
                    <svg
                        class="w-5 h-5 text-success mt-0.5"
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
                    <div>
                        <div class="font-medium text-success">
                            Perfect! All correct
                        </div>
                        <div class="text-sm text-base-content/70 mt-1">
                            You selected {selectedOptions.length} of {data
                                .correct_indices.length} correct answers
                        </div>
                    </div>
                {:else}
                    <svg
                        class="w-5 h-5 text-error mt-0.5"
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
                    <div class="flex-1">
                        <div class="font-medium text-error mb-2">
                            Review your answers
                        </div>
                        <div
                            class="grid grid-cols-1 sm:grid-cols-3 gap-3 text-sm"
                        >
                            {#if correctCount > 0}
                                <div
                                    class="flex items-center gap-2 text-success"
                                >
                                    <svg
                                        class="w-4 h-4"
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
                                    <span>{correctCount} correct</span>
                                </div>
                            {/if}
                            {#if incorrectCount > 0}
                                <div class="flex items-center gap-2 text-error">
                                    <svg
                                        class="w-4 h-4"
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
                                    <span>{incorrectCount} incorrect</span>
                                </div>
                            {/if}
                            {#if missedCount > 0}
                                <div
                                    class="flex items-center gap-2 text-warning"
                                >
                                    <svg
                                        class="w-4 h-4"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M12 9v2m0 4h.01"
                                        />
                                    </svg>
                                    <span>{missedCount} missed</span>
                                </div>
                            {/if}
                        </div>
                    </div>
                {/if}
            </div>
        </div>
    {/if}
</div>
