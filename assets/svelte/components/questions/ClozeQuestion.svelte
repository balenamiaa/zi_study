<script>
        import MarkdownContent from "../MarkdownContent.svelte";
    
    let { data, userAnswer = null, submitAnswer, clearAnswer } = $props();
    
    let answers = $state(() => {
        if (userAnswer?.data?.answers) {
            // Convert array to object for editing
            const answersObj = {};
            userAnswer.data.answers.forEach((answer, index) => {
                answersObj[index] = answer;
            });
            return answersObj;
        }
        return {};
    });
    let showExplanation = $state(false);
    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);

    // Parse the question text to find cloze patterns
    let parsedQuestion = $derived.by(() => {
        let text = data.question_text;
        let clozeIndex = 1;

        // Replace {{c1::hint}} patterns with input fields
        text = text.replace(/\{\{c(\d+)::([^}]+)\}\}/g, (match, num, hint) => {
            const index = parseInt(num) - 1;
            return `<span class="cloze-placeholder" data-index="${index}" data-hint="${hint}"></span>`;
        });

        return text;
    });

    function checkAnswers() {
        const answersArray = [];
        for (let i = 0; i < data.answers.length; i++) {
            answersArray[i] = answers[i] || "";
        }
        submitAnswer({
            answers: answersArray
        });
    }

    function handleAnswerChange(index, value) {
        if (!isAnswered) {
            answers[index] = value;
        }
    }

    function isAnswerCorrect(index) {
        if (!isAnswered) return false;
        const userAnswer = answers[index] || "";
        const correctAnswer = data.answers[index];
        const userAnswerLower = userAnswer.toLowerCase().trim();
        const correctAnswerLower = correctAnswer.toLowerCase().trim();
        return userAnswerLower === correctAnswerLower;
    }

    let allAnswered = $derived.by(() => {
        return data.answers.every((_, index) => answers[index]?.trim());
    });
</script>

<div class="space-y-4">
    <!-- Question Text with Input Fields -->
    <div class="text-lg font-medium text-base-content leading-relaxed">
        <div class="cloze-question leading-loose">
            {#each parsedQuestion.split('<span class="cloze-placeholder"') as part, i}
                {#if i === 0}
                    {part}
                {:else}
                    {@const indexMatch = part.match(/data-index="(\d+)"/)}
                    {@const hintMatch = part.match(/data-hint="([^"]+)"/)}
                    {@const index = indexMatch ? parseInt(indexMatch[1]) : 0}
                    {@const hint = hintMatch ? hintMatch[1] : ""}
                    {@const afterSpan = part.split("></span>")[1] || ""}

                    <span class="inline-flex items-center relative">
                        {#if isAnswered}
                            <span
                                class="px-2 py-1 {isAnswerCorrect(index)
                                    ? 'bg-success/20 text-success border-b-2 border-success'
                                    : 'bg-error/20 text-error border-b-2 border-error'}"
                            >
                                {answers[index] || "(empty)"}
                            </span>
                        {:else}
                            <input
                                type="text"
                                value={answers[index] || ""}
                                oninput={(e) =>
                                    handleAnswerChange(index, e.target.value)}
                                placeholder={hint}
                                class="input input-bordered input-sm min-w-[100px] mx-1 text-center bg-base-100 border-b-2 border-primary/30 focus:border-primary"
                            />
                        {/if}
                    </span>
                    {afterSpan}
                {/if}
            {/each}
        </div>
    </div>

    <!-- Instructions -->
    {#if !isAnswered}
        <div class="text-sm text-base-content/60 italic">
            Fill in the blanks with the correct answers
        </div>
    {/if}

    <!-- Action Buttons -->
    {#if !isAnswered}
        <div class="flex gap-2">
            <button
                class="btn btn-primary btn-sm"
                onclick={checkAnswers}
                disabled={!allAnswered}
            >
                Check Answers
            </button>
        </div>
    {/if}

    <!-- Answer Feedback -->
    {#if isAnswered}
        <div class="space-y-3">
            {#each data.answers as correctAnswer, index}
                {@const userAnswer = answers[index] || ""}
                {@const correct = isAnswerCorrect(index)}

                <div
                    class="p-3 rounded-lg border {correct
                        ? 'bg-success/10 border-success/20'
                        : 'bg-error/10 border-error/20'}"
                >
                    <div class="flex items-start gap-2">
                        {#if correct}
                            <svg
                                class="w-4 h-4 text-success mt-0.5"
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
                        {:else}
                            <svg
                                class="w-4 h-4 text-error mt-0.5"
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
                        {/if}
                        <div class="text-sm">
                            <div class="font-medium">Blank {index + 1}</div>
                            <div class="text-base-content/70">
                                Your answer: <span class="font-mono"
                                    >{userAnswer || "(empty)"}</span
                                >
                            </div>
                            {#if !correct}
                                <div class="text-success">
                                    Correct answer: <span class="font-mono"
                                        >{correctAnswer}</span
                                    >
                                </div>
                            {/if}
                        </div>
                    </div>
                </div>
            {/each}
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
