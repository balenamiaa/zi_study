<script>
    import QuestionToolbar from "./QuestionToolbar.svelte";
    import ExplanationPanel from "./ExplanationPanel.svelte";
    import TextArea from "../TextArea.svelte";
    import { setupQuestionEvents, createSubmissionHandler, isAnswerValid } from "../../utils/questionUtils.js";

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

    let answerText = $state(userAnswer?.data?.answer_text || "");
    let showExplanation = $state(false);
    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);
    let isSubmitting = $state(false);
    let showSelfEvaluation = $state(false);
    let canSubmit = $derived(isAnswerValid(answerText, 'text'));

    const handleSubmission = createSubmissionHandler(submitAnswer, (loading) => isSubmitting = loading);

    function handleSubmitAnswer() {
        if (canSubmit && !isSubmitting) {
            handleSubmission({
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
        answerText = "";
        showSelfEvaluation = false;
    }

    function handleSelfEvaluation(isCorrect) {
        if (live) {
            live.pushEvent("self_evaluate_answer", {
                question_id: data.id?.toString() || questionNumber.toString(),
                is_correct: isCorrect,
            });
        }
        showSelfEvaluation = false;
    }

    function handleAnswerSubmitted() {
        isSubmitting = false;
    }

    $effect(() => {
        return setupQuestionEvents(live, handleAnswerSubmitted, null);
    });

    $effect(() => {
        if (userAnswer) {
            isSubmitting = false;

            if (userAnswer.is_correct === 2) {
                showSelfEvaluation = true;
            } else {
                showSelfEvaluation = false;
            }
        } else {
            showSelfEvaluation = false;
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
        onClearAnswer={handleClearAnswer}
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

    <!-- Answer Input -->
    {#if !isAnswered}
        <div class="space-y-3">
            <TextArea
                value={answerText}
                oninput={handleAnswerChange}
                placeholder="Type your answer here..."
                disabled={isAnswered}
                rows={1}
                class="w-full"
            />
        </div>

        <!-- Action Buttons -->
        <div class="flex gap-2">
            <button
                class="btn btn-primary btn-sm relative"
                onclick={handleSubmitAnswer}
                disabled={!canSubmit || isSubmitting}
            >
                {#if isSubmitting}
                    <span class="loading loading-spinner loading-xs"></span>
                    Submitting...
                {:else}
                    Submit Answer
                {/if}
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

            <!-- Self-Evaluation -->
            {#if showSelfEvaluation && userAnswer?.is_correct === 2}
                <div class="p-4 bg-info/10 border border-info/20 rounded-lg">
                    <div class="flex items-start gap-2 mb-3">
                        <svg
                            class="w-4 h-4 text-info mt-0.5"
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
                        <div>
                            <div class="text-sm font-medium text-info">
                                Self-Evaluation Required
                            </div>
                            <div class="text-xs text-base-content/70 mt-1">
                                Compare your answer with the model answer above
                                and evaluate yourself.
                            </div>
                        </div>
                    </div>

                    <div class="flex gap-3 pl-6">
                        <button
                            class="btn btn-success btn-sm"
                            onclick={() => handleSelfEvaluation(true)}
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
                            Correct
                        </button>
                        <button
                            class="btn btn-error btn-sm"
                            onclick={() => handleSelfEvaluation(false)}
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
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                            Incorrect
                        </button>
                    </div>
                </div>
            {:else if userAnswer?.is_correct === 1}
                <div
                    class="p-3 bg-success/10 border border-success/20 rounded-lg"
                >
                    <div class="flex items-center gap-2">
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
                        <span class="text-sm font-medium text-success"
                            >You marked this as correct</span
                        >
                    </div>
                </div>
            {:else if userAnswer?.is_correct === 0}
                <div class="p-3 bg-error/10 border border-error/20 rounded-lg">
                    <div class="flex items-center gap-2">
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
                        <span class="text-sm font-medium text-error"
                            >You marked this as incorrect</span
                        >
                    </div>
                </div>
            {/if}
        </div>
    {/if}
</div>
