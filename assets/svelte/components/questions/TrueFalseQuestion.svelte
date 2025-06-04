<script>
    import QuestionToolbar from "./QuestionToolbar.svelte";
    import QuestionFeedback from "./QuestionFeedback.svelte";
    import ExplanationPanel from "./ExplanationPanel.svelte";

    let {
        data,
        userAnswer = null,
        submitAnswer,
        clearAnswer,
        questionNumber,
    } = $props();

    let selectedAnswer = $state(userAnswer?.data?.is_true ?? null);
    let showExplanation = $state(false);
    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);

    function handleAnswerSelect(answer) {
        if (!isAnswered) {
            selectedAnswer = answer;
            submitAnswer({
                is_true: answer,
            });
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
            class="flex items-start gap-3 p-4 rounded-lg border border-base-300 transition-all duration-200 {selectedAnswer ===
            true
                ? 'border-primary bg-primary/5'
                : isAnswered
                  ? ''
                  : 'hover:border-primary/50 cursor-pointer hover:bg-base-100'} {isAnswered
                ? 'cursor-default'
                : 'cursor-pointer'}"
        >
            <input
                type="radio"
                name="true-false-option"
                value={true}
                checked={selectedAnswer === true}
                onchange={() => handleAnswerSelect(true)}
                disabled={isAnswered}
                class="radio radio-primary mt-1"
            />
            <div class="flex-1">
                <div class="flex items-center gap-3">
                    <div
                        class="w-8 h-8 bg-success text-success-content rounded-full flex items-center justify-center font-bold"
                    >
                        T
                    </div>
                    <span class="text-base-content font-medium">True</span>
                </div>
            </div>
        </label>

        <label
            class="flex items-start gap-3 p-4 rounded-lg border border-base-300 transition-all duration-200 {selectedAnswer ===
            false
                ? 'border-primary bg-primary/5'
                : isAnswered
                  ? ''
                  : 'hover:border-primary/50 cursor-pointer hover:bg-base-100'} {isAnswered
                ? 'cursor-default'
                : 'cursor-pointer'}"
        >
            <input
                type="radio"
                name="true-false-option"
                value={false}
                checked={selectedAnswer === false}
                onchange={() => handleAnswerSelect(false)}
                disabled={isAnswered}
                class="radio radio-primary mt-1"
            />
            <div class="flex-1">
                <div class="flex items-center gap-3">
                    <div
                        class="w-8 h-8 bg-error text-error-content rounded-full flex items-center justify-center font-bold"
                    >
                        F
                    </div>
                    <span class="text-base-content font-medium">False</span>
                </div>
            </div>
        </label>
    </div>

    <!-- Answer Feedback -->
    {#if isAnswered && selectedAnswer !== null}
        {@const isCorrect = userAnswer?.is_correct === 1}

        <QuestionFeedback
            {isCorrect}
            userResponse={selectedAnswer ? "True" : "False"}
            correctResponse={!isCorrect
                ? data.is_correct_true
                    ? "True"
                    : "False"
                : null}
        />
    {/if}
</div>
