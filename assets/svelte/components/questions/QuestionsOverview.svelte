<script>
    import { twMerge } from "tailwind-merge";
    import MarkdownContent from "../MarkdownContent.svelte";
    import { formatClozeForDisplay } from "../../utils/clozeUtils.js";

    let {
        questionSet,
        filteredQuestions,
        currentQuestionIndex = $bindable(0),
        handleSliderChange,
        class: userClass = "",
    } = $props();

    let totalQuestions = $derived(questionSet?.questions?.length || 0);
    let answeredQuestions = $derived(questionSet?.stats?.total_answers || 0);
    let correctAnswers = $derived(questionSet?.stats?.correct_answers || 0);

    let completionPercentage = $derived.by(() => {
        if (totalQuestions === 0) return 0;
        return Math.round((answeredQuestions / totalQuestions) * 100);
    });

    let accuracyPercentage = $derived.by(() => {
        if (answeredQuestions === 0) return 0;
        return Math.round((correctAnswers / answeredQuestions) * 100);
    });

    function onSliderChange(event) {
        const value = parseInt(event.target.value);
        currentQuestionIndex = value;
        handleSliderChange(value);
    }

    function formatNumber(num) {
        return num.toLocaleString();
    }

    // Get a preview of the question text, handling cloze questions specially
    function getQuestionPreview(question) {
        const questionText = question.data.question_text || '';
        
        if (question.data.question_type === 'cloze') {
            // Use formatClozeForDisplay to show blanks as [___] instead of hints
            return formatClozeForDisplay(questionText, false);
        }
        
        return questionText;
    }

    let sliderSteps = $derived.by(() => {
        const length = filteredQuestions.length;
        if (length <= 10) return Array.from({ length }, (_, i) => i + 1);

        const steps = [];
        const stepSize = Math.max(1, Math.floor(length / 9));
        for (let i = 0; i < 10; i++) {
            const questionNum = Math.min(i * stepSize + 1, length);
            steps.push(questionNum);
        }
        return steps;
    });
</script>

<div class={twMerge("bg-base-200 border-b border-base-300", userClass)}>
    <div class="max-w-7xl mx-auto p-4 md:p-6">
        <div class="space-y-6">
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div class="bg-base-100 rounded-lg p-4 text-center">
                    <div
                        class="text-2xl md:text-3xl font-bold text-base-content"
                    >
                        {formatNumber(totalQuestions)}
                    </div>
                    <div
                        class="text-xs md:text-sm text-base-content/60 uppercase tracking-wide"
                    >
                        Total Questions
                    </div>
                </div>

                <div class="bg-base-100 rounded-lg p-4 text-center">
                    <div class="text-2xl md:text-3xl font-bold text-primary">
                        {formatNumber(answeredQuestions)}
                    </div>
                    <div
                        class="text-xs md:text-sm text-base-content/60 uppercase tracking-wide"
                    >
                        Answered
                    </div>
                </div>

                <div class="bg-base-100 rounded-lg p-4 text-center">
                    <div class="text-2xl md:text-3xl font-bold text-success">
                        {formatNumber(correctAnswers)}
                    </div>
                    <div
                        class="text-xs md:text-sm text-base-content/60 uppercase tracking-wide"
                    >
                        Correct
                    </div>
                </div>

                <div class="bg-base-100 rounded-lg p-4 text-center">
                    <div class="text-2xl md:text-3xl font-bold text-accent">
                        {accuracyPercentage}%
                    </div>
                    <div
                        class="text-xs md:text-sm text-base-content/60 uppercase tracking-wide"
                    >
                        Accuracy
                    </div>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="bg-base-100 rounded-lg p-4">
                    <div class="flex justify-between items-center mb-2">
                        <span class="text-sm font-medium text-base-content"
                            >Questions Answered</span
                        >
                        <span class="text-sm text-base-content/70">
                            {answeredQuestions} of {totalQuestions}
                        </span>
                    </div>
                    <div
                        class="w-full bg-base-300 rounded-full h-3 overflow-hidden"
                    >
                        <div
                            class="bg-primary h-3 rounded-full transition-all duration-500 ease-out"
                            style="width: {completionPercentage}%"
                        ></div>
                    </div>
                    <div class="text-xs text-base-content/60 mt-1">
                        {completionPercentage}% Complete
                    </div>
                </div>

                <div class="bg-base-100 rounded-lg p-4">
                    <div class="flex justify-between items-center mb-2">
                        <span class="text-sm font-medium text-base-content"
                            >Correct Answers</span
                        >
                        <span class="text-sm text-base-content/70">
                            {correctAnswers} of {answeredQuestions}
                        </span>
                    </div>
                    <div
                        class="w-full bg-base-300 rounded-full h-3 overflow-hidden"
                    >
                        <div
                            class="bg-success h-3 rounded-full transition-all duration-500 ease-out"
                            style="width: {accuracyPercentage}%"
                        ></div>
                    </div>
                    <div class="text-xs text-base-content/60 mt-1">
                        {accuracyPercentage}% Accuracy
                    </div>
                </div>
            </div>

            {#if filteredQuestions.length > 0}
                <div class="bg-base-100 rounded-lg p-4">
                    <div class="flex justify-between items-center mb-3">
                        <span class="text-sm font-medium text-base-content"
                            >Question Navigation</span
                        >
                        <span class="text-sm text-base-content/70">
                            Question {currentQuestionIndex + 1} of {filteredQuestions.length}
                        </span>
                    </div>

                    <div class="space-y-2">
                        <input
                            type="range"
                            min="0"
                            max={filteredQuestions.length - 1}
                            value={currentQuestionIndex}
                            oninput={onSliderChange}
                            class="range range-primary w-full"
                        />

                        <div
                            class="flex justify-between text-xs text-base-content/40 px-1"
                        >
                            {#each sliderSteps as questionNum}
                                <span>{questionNum}</span>
                            {/each}
                        </div>
                    </div>

                    {#if filteredQuestions[currentQuestionIndex]}
                        {@const currentQuestion =
                            filteredQuestions[currentQuestionIndex]}
                        {@const userAnswer = questionSet?.answers?.find(
                            (a) => a.question_id === currentQuestion.id,
                        )}
                        <div class="mt-4 p-3 bg-base-200 rounded-lg">
                            <div
                                class="text-sm text-base-content line-clamp-2 mb-2"
                            >
                                {getQuestionPreview(currentQuestion)}
                            </div>
                            <div class="flex gap-2 items-center">
                                {#if currentQuestion.data.difficulty}
                                    <span class="badge badge-outline badge-xs">
                                        Difficulty: {currentQuestion.data
                                            .difficulty}
                                    </span>
                                {/if}
                            </div>
                        </div>
                    {/if}
                </div>
            {/if}
        </div>
    </div>
</div>

<style>
    .line-clamp-2 {
        display: -webkit-box;
        line-clamp: 2;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }
</style>
