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

    let selectedOption = $state(userAnswer?.data?.selected_index ?? null);
    let showExplanation = $state(false);
    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);

    function handleOptionSelect(index) {
        if (!isAnswered) {
            selectedOption = index;
            submitAnswer({
                selected_index: index,
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

    <!-- Options -->
    <div class="space-y-3">
        {#each data.options as option, index}
            <label
                class="flex items-start gap-3 p-3 rounded-lg border border-base-300 transition-all duration-200 {selectedOption ===
                index
                    ? 'border-primary bg-primary/5'
                    : isAnswered
                      ? ''
                      : 'hover:border-primary/50 cursor-pointer hover:bg-base-100'} {isAnswered
                    ? 'cursor-default'
                    : 'cursor-pointer'}"
            >
                <input
                    type="radio"
                    name="mcq-single-option"
                    value={index}
                    checked={selectedOption === index}
                    onchange={() => handleOptionSelect(index)}
                    disabled={isAnswered}
                    class="radio radio-primary mt-1"
                />
                <div class="flex-1">
                    <span class="text-base-content">{option}</span>
                </div>
            </label>
        {/each}
    </div>

    <!-- Answer Feedback -->
    {#if isAnswered && selectedOption !== null}
        {@const isCorrect = userAnswer?.is_correct === 1}

        <QuestionFeedback
            {isCorrect}
            userResponse={data.options[selectedOption]}
            correctResponse={!isCorrect
                ? data.options[data.correct_index]
                : null}
        />
    {/if}
</div>
