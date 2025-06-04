<script>
    import QuestionToolbar from "./QuestionToolbar.svelte";
    import ExplanationPanel from "./ExplanationPanel.svelte";

    let {
        data,
        userAnswer = null,
        submitAnswer,
        clearAnswer,
        questionNumber,
        live,
    } = $props();

    let selectedMatches = $state(userAnswer?.data?.matches || []);
    let showExplanation = $state(false);
    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);
    let isSubmitting = $state(false);

    let allAnswered = $derived(
        data.premises.length > 0 &&
            selectedMatches.length === data.premises.length
    );

    function handleMatchChange(premiseIndex, optionIndex) {
        if (!isAnswered && !isSubmitting) {
            const newMatches = [...selectedMatches];
            
            // Find existing match for this premise, or create new one
            const existingMatchIndex = newMatches.findIndex(match => match.premise_index === premiseIndex);
            
            if (existingMatchIndex !== -1) {
                if (optionIndex === "" || optionIndex === null) {
                    // Remove the match if option is cleared
                    newMatches.splice(existingMatchIndex, 1);
                } else {
                    // Update existing match
                    newMatches[existingMatchIndex] = {
                        premise_index: premiseIndex,
                        option_index: parseInt(optionIndex)
                    };
                }
            } else if (optionIndex !== "" && optionIndex !== null) {
                // Add new match
                newMatches.push({
                    premise_index: premiseIndex,
                    option_index: parseInt(optionIndex)
                });
            }
            
            selectedMatches = newMatches;
        }
    }

    function checkAnswer() {
        if (allAnswered && !isSubmitting) {
            isSubmitting = true;
            submitAnswer({
                matches: selectedMatches
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
                    selectedMatches = [];
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

    function getSelectedOptionForPremise(premiseIndex) {
        const match = selectedMatches.find(m => m.premise_index === premiseIndex);
        return match ? match.option_index : null;
    }

    function getCorrectOptionForPremise(premiseIndex) {
        // data.matches is likely in format [[premise_index, option_index], ...]
        const match = data.matches.find(m => Array.isArray(m) ? m[0] === premiseIndex : m.premise_index === premiseIndex);
        return match ? (Array.isArray(match) ? match[1] : match.option_index) : null;
    }

    function isMatchCorrect(premiseIndex) {
        if (!isAnswered) return false;
        const selected = getSelectedOptionForPremise(premiseIndex);
        const correct = getCorrectOptionForPremise(premiseIndex);
        return selected === correct;
    }

    function isMatchIncorrect(premiseIndex) {
        if (!isAnswered) return false;
        const selected = getSelectedOptionForPremise(premiseIndex);
        const correct = getCorrectOptionForPremise(premiseIndex);
        return selected !== null && selected !== correct;
    }
</script>

<div class="space-y-4">
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

    <div class="text-lg font-medium text-base-content leading-relaxed">
        {data.question_text}
    </div>

    {#if data.instructions}
        <div class="text-sm text-base-content/70 italic bg-base-200/50 p-3 rounded-lg">
            {data.instructions}
        </div>
    {/if}

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Premises Column -->
        <div class="space-y-4">
            <div class="text-base font-semibold text-base-content border-b border-base-300 pb-2">
                Premises
            </div>
            <div class="space-y-3">
                {#each data.premises as premise, premiseIndex}
                    {@const isCorrect = isMatchCorrect(premiseIndex)}
                    {@const isIncorrect = isMatchIncorrect(premiseIndex)}
                    
                    <div class="p-4 rounded-lg border transition-all duration-200 {
                        isCorrect 
                            ? 'border-success bg-success/5' 
                            : isIncorrect 
                            ? 'border-error bg-error/5'
                            : 'border-base-300 bg-base-100'
                    }">
                        <div class="flex items-start gap-3">
                            <div class="w-8 h-8 bg-primary text-primary-content rounded-full flex items-center justify-center text-sm font-bold shrink-0">
                                {premiseIndex + 1}
                            </div>
                            <div class="flex-1">
                                <div class="text-sm text-base-content leading-relaxed">
                                    {premise}
                                </div>
                                
                                {#if isAnswered}
                                    <div class="mt-2 flex items-center gap-2">
                                        {#if isCorrect}
                                            <svg class="w-4 h-4 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                            </svg>
                                            <span class="text-xs text-success font-medium">Correct match</span>
                                        {:else if isIncorrect}
                                            <svg class="w-4 h-4 text-error" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                            </svg>
                                            <span class="text-xs text-error font-medium">
                                                Correct: {data.options[getCorrectOptionForPremise(premiseIndex)]}
                                            </span>
                                        {/if}
                                    </div>
                                {/if}
                            </div>
                        </div>
                    </div>
                {/each}
            </div>
        </div>

        <!-- Options and Matches Column -->
        <div class="space-y-4">
            <div class="text-base font-semibold text-base-content border-b border-base-300 pb-2">
                Options & Matches
            </div>
            
            <!-- Options Reference -->
            <div class="p-4 bg-base-200/30 rounded-lg">
                <div class="text-sm font-medium text-base-content mb-2">Available Options:</div>
                <div class="grid grid-cols-1 gap-2">
                    {#each data.options as option, optionIndex}
                        <div class="flex items-center gap-2 text-sm">
                            <div class="w-6 h-6 bg-secondary text-secondary-content rounded-full flex items-center justify-center text-xs font-bold">
                                {String.fromCharCode(65 + optionIndex)}
                            </div>
                            <span class="text-base-content/80">{option}</span>
                        </div>
                    {/each}
                </div>
            </div>

            <!-- Match Selectors -->
            <div class="space-y-3">
                {#each data.premises as _, premiseIndex}
                    {@const selectedOption = getSelectedOptionForPremise(premiseIndex)}
                    {@const isCorrect = isMatchCorrect(premiseIndex)}
                    {@const isIncorrect = isMatchIncorrect(premiseIndex)}
                    
                    <div class="flex items-center gap-3 p-3 rounded-lg border {
                        isCorrect 
                            ? 'border-success bg-success/5' 
                            : isIncorrect 
                            ? 'border-error bg-error/5'
                            : 'border-base-300'
                    }">
                        <div class="w-8 h-8 bg-primary text-primary-content rounded-full flex items-center justify-center text-sm font-bold">
                            {premiseIndex + 1}
                        </div>
                        
                        <svg class="w-4 h-4 text-base-content/50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                        </svg>
                        
                        <select
                            value={selectedOption ?? ""}
                            onchange={(e) => handleMatchChange(premiseIndex, e.target.value)}
                            disabled={isAnswered || isSubmitting}
                            class="select select-bordered flex-1 {
                                isCorrect 
                                    ? 'select-success' 
                                    : isIncorrect 
                                    ? 'select-error'
                                    : 'select-primary'
                            }"
                        >
                            <option value="">Choose an option...</option>
                            {#each data.options as option, optionIndex}
                                <option value={optionIndex}>
                                    {String.fromCharCode(65 + optionIndex)}: {option}
                                </option>
                            {/each}
                        </select>

                        {#if isAnswered}
                            {#if isCorrect}
                                <svg class="w-5 h-5 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                </svg>
                            {:else if isIncorrect}
                                <svg class="w-5 h-5 text-error" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                </svg>
                            {/if}
                        {/if}
                    </div>
                {/each}
            </div>
        </div>
    </div>

    {#if !isAnswered}
        <div class="text-sm text-base-content/60 italic text-center">
            Match each premise with the most appropriate option
        </div>
    {/if}

    {#if !isAnswered}
        <div class="flex justify-center">
            <button
                class="btn btn-primary relative"
                onclick={checkAnswer}
                disabled={!allAnswered || isSubmitting}
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
        {@const correctCount = data.premises.filter((_, i) => isMatchCorrect(i)).length}
        
        <div class="p-4 rounded-lg {isCorrect ? 'bg-success/10 border border-success/20' : 'bg-base-100 border border-base-300'}">
            <div class="flex items-start gap-3">
                {#if isCorrect}
                    <svg class="w-5 h-5 text-success mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                    <div>
                        <div class="font-medium text-success">Perfect! All matches correct</div>
                        <div class="text-sm text-base-content/70 mt-1">
                            You correctly matched all {data.premises.length} premises
                        </div>
                    </div>
                {:else}
                    <svg class="w-5 h-5 text-error mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    <div>
                        <div class="font-medium text-error">Review your matches</div>
                        <div class="text-sm text-base-content/70 mt-1">
                            {correctCount} of {data.premises.length} matches correct. Check the corrections above.
                        </div>
                    </div>
                {/if}
            </div>
        </div>
    {/if}
</div> 