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
    } = $props();

    let selectedAnswer = $state(userAnswer?.data?.is_true ?? null);
    let showExplanation = $state(false);
    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);
    let isSubmitting = $state(false);

    function handleAnswerSelect(answer) {
        if (!isAnswered && !isSubmitting) {
            selectedAnswer = answer;
            isSubmitting = true;
            submitAnswer({
                is_true: answer,
            });
        }
    }

    function handleClearAnswer() {
        clearAnswer();
    }

    // Listen for backend events
    $effect(() => {
        if (live) {
            const handleAnswerSubmitted = () => {
                isSubmitting = false;
            };

            const handleAnswerReset = (payload) => {
                const eventQuestionId = payload.question_id;
                const currentQuestionId = data?.id?.toString() || questionNumber?.toString();
                if (eventQuestionId === currentQuestionId) {
                    selectedAnswer = null;
                    isSubmitting = false;
                }
            };

            live.handleEvent("answer_submitted", handleAnswerSubmitted);
            live.handleEvent("answer_reset", handleAnswerReset);

            return () => {
                if (live) {
                    live.removeHandleEvent("answer_submitted", handleAnswerSubmitted);
                    live.removeHandleEvent("answer_reset", handleAnswerReset);
                }
            };
        }
    });

    // Reset submitting state when answer is received
    $effect(() => {
        if (userAnswer) {
            isSubmitting = false;
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
    >
        {#if data.explanation && isAnswered}
            <ExplanationPanel explanation={data.explanation} />
        {/if}
    </QuestionToolbar>

    <!-- Question Text -->
    <div class="text-lg font-medium text-base-content leading-relaxed">
        {data.question_text}
    </div>

    <!-- Answer Options -->
    <div class="space-y-3">
        <label
            class="flex items-start gap-3 p-4 rounded-lg border transition-all duration-200 {
                isAnswered && data.is_correct_true && selectedAnswer === true
                    ? 'border-success bg-success/10'
                    : isAnswered && !data.is_correct_true && selectedAnswer === true
                    ? 'border-error bg-error/10'
                    : selectedAnswer === true
                    ? 'border-primary bg-primary/5'
                    : isAnswered || isSubmitting
                    ? 'border-base-300'
                    : 'border-base-300 hover:border-primary/50 cursor-pointer hover:bg-base-100'
            } {
                isAnswered || isSubmitting ? 'cursor-default' : 'cursor-pointer'
            }"
        >
            <RadioWithSpinner
                name="true-false-option-{questionNumber}"
                value={true}
                checked={selectedAnswer === true}
                onchange={() => handleAnswerSelect(true)}
                disabled={isAnswered || isSubmitting}
                showSpinner={isSubmitting && selectedAnswer === true}
                variant={isAnswered && data.is_correct_true 
                    ? 'success' 
                    : isAnswered && selectedAnswer === true && !data.is_correct_true 
                    ? 'error' 
                    : 'primary'}
            />
            <div class="flex-1">
                <div class="flex items-center gap-3">
                    <div
                        class="w-8 h-8 bg-success text-success-content rounded-full flex items-center justify-center font-bold"
                    >
                        T
                    </div>
                    <span class="text-base-content font-medium {
                        isAnswered && data.is_correct_true 
                            ? 'text-success' 
                            : isAnswered && selectedAnswer === true && !data.is_correct_true 
                            ? 'text-error' 
                            : ''
                    }">True</span>
                    {#if isAnswered && data.is_correct_true}
                        <svg class="w-4 h-4 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                    {:else if isAnswered && selectedAnswer === true && !data.is_correct_true}
                        <svg class="w-4 h-4 text-error" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    {/if}
                </div>
            </div>
        </label>

        <label
            class="flex items-start gap-3 p-4 rounded-lg border transition-all duration-200 {
                isAnswered && !data.is_correct_true && selectedAnswer === false
                    ? 'border-success bg-success/10'
                    : isAnswered && data.is_correct_true && selectedAnswer === false
                    ? 'border-error bg-error/10'
                    : selectedAnswer === false
                    ? 'border-primary bg-primary/5'
                    : isAnswered || isSubmitting
                    ? 'border-base-300'
                    : 'border-base-300 hover:border-primary/50 cursor-pointer hover:bg-base-100'
            } {
                isAnswered || isSubmitting ? 'cursor-default' : 'cursor-pointer'
            }"
        >
            <RadioWithSpinner
                name="true-false-option-{questionNumber}"
                value={false}
                checked={selectedAnswer === false}
                onchange={() => handleAnswerSelect(false)}
                disabled={isAnswered || isSubmitting}
                showSpinner={isSubmitting && selectedAnswer === false}
                variant={isAnswered && !data.is_correct_true 
                    ? 'success' 
                    : isAnswered && selectedAnswer === false && data.is_correct_true 
                    ? 'error' 
                    : 'primary'}
            />
            <div class="flex-1">
                <div class="flex items-center gap-3">
                    <div
                        class="w-8 h-8 bg-error text-error-content rounded-full flex items-center justify-center font-bold"
                    >
                        F
                    </div>
                    <span class="text-base-content font-medium {
                        isAnswered && !data.is_correct_true 
                            ? 'text-success' 
                            : isAnswered && selectedAnswer === false && data.is_correct_true 
                            ? 'text-error' 
                            : ''
                    }">False</span>
                    {#if isAnswered && !data.is_correct_true}
                        <svg class="w-4 h-4 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                    {:else if isAnswered && selectedAnswer === false && data.is_correct_true}
                        <svg class="w-4 h-4 text-error" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    {/if}
                </div>
            </div>
        </label>
    </div>
</div>
