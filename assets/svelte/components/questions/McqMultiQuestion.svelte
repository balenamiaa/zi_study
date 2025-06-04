<script>
    import MarkdownContent from "../MarkdownContent.svelte";
    
    let { data, userAnswer = null, submitAnswer, clearAnswer } = $props();

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
</script>

<div class="space-y-4">
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
        <div
            class="mt-4 p-4 rounded-lg {isCorrect
                ? 'bg-success/10 border border-success/20'
                : 'bg-error/10 border border-error/20'}"
        >
            <div class="flex items-start gap-2">
                {#if isCorrect}
                    <svg
                        class="w-5 h-5 text-success mt-0.5"
                        xmlns="http://www.w3.org/2000/svg"
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
                        <div class="font-medium text-success">Correct!</div>
                        <div class="text-sm text-base-content/70 mt-1">
                            You selected: {selectedOptions
                                .map((i) => data.options[i])
                                .join(", ")}
                        </div>
                    </div>
                {:else}
                    <svg
                        class="w-5 h-5 text-error mt-0.5"
                        xmlns="http://www.w3.org/2000/svg"
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
                    <div>
                        <div class="font-medium text-error">Incorrect</div>
                        <div class="text-sm text-base-content/70 mt-1">
                            You selected: {selectedOptions
                                .map((i) => data.options[i])
                                .join(", ")}
                        </div>
                        <div class="text-sm text-success mt-1">
                            Correct answers: {data.correct_indices
                                .map((i) => data.options[i])
                                .join(", ")}
                        </div>
                    </div>
                {/if}
            </div>
        </div>
    {/if}

    <!-- Question Actions Toolbar -->
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
