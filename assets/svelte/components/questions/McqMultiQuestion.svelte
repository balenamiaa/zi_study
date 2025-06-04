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

    let selectedOptions = $state(userAnswer?.data?.selected_indices ?? []);
    let showExplanation = $state(false);
    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);

    function handleOptionToggle(index) {
        if (!isAnswered) {
            if (selectedOptions.includes(index)) {
                selectedOptions = selectedOptions.filter((i) => i !== index);
            } else {
                selectedOptions = [...selectedOptions, index];
            }
        }
    }

    function checkAnswer() {
        if (selectedOptions.length > 0) {
            submitAnswer({
                selected_indices: selectedOptions,
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
                class="flex items-start gap-3 p-3 rounded-lg border border-base-300 transition-all duration-200 {selectedOptions.includes(
                    index,
                )
                    ? 'border-primary bg-primary/5'
                    : isAnswered
                      ? ''
                      : 'hover:border-primary/50 cursor-pointer hover:bg-base-100'} {isAnswered
                    ? 'cursor-default'
                    : 'cursor-pointer'}"
            >
                <input
                    type="checkbox"
                    checked={selectedOptions.includes(index)}
                    onchange={() => handleOptionToggle(index)}
                    disabled={isAnswered}
                    class="checkbox checkbox-primary mt-1"
                />
                <div class="flex-1">
                    <span class="text-base-content">{option}</span>
                </div>
            </label>
        {/each}
    </div>

    <!-- Instructions -->
    {#if !isAnswered}
        <div class="text-sm text-base-content/60 italic">
            Select all correct answers
        </div>
    {/if}

    <!-- Check Answer Button -->
    {#if !isAnswered}
        <div class="flex gap-2">
            <button
                class="btn btn-primary btn-sm"
                onclick={checkAnswer}
                disabled={selectedOptions.length === 0}
            >
                Check Answer
            </button>
        </div>
    {/if}

    <!-- Answer Feedback -->
    {#if isAnswered && selectedOptions.length > 0}
        {@const isCorrect = userAnswer?.is_correct === 1}

        <QuestionFeedback {isCorrect}>
            <svelte:fragment slot="user-response">
                You selected: {selectedOptions
                    .map((i) => data.options[i])
                    .join(", ")}
            </svelte:fragment>

            <svelte:fragment slot="correct-response">
                {#if !isCorrect}
                    Correct answers: {data.correct_indices
                        .map((i) => data.options[i])
                        .join(", ")}
                {/if}
            </svelte:fragment>
        </QuestionFeedback>
    {/if}
</div>
