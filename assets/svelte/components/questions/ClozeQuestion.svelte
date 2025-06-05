<script>
    import QuestionToolbar from "./QuestionToolbar.svelte";
    import ExplanationPanel from "./ExplanationPanel.svelte";
    import ClozeInput from "./ClozeInput.svelte";
    import { parseClozeText } from "../../utils/clozeUtils.js";

    let {
        data,
        userAnswer = null,
        submitAnswer,
        clearAnswer,
        questionNumber,
        live,
    } = $props();

    let { clozes, processedText } = parseClozeText(data.question_text);

    let clozeAnswers = $state(
        userAnswer?.data?.answers || new Array(clozes.length).fill(""),
    );

    let showExplanation = $state(false);
    let isSubmitting = $state(false);
    let answerSubmittedHandleRef = $state(null);
    let answerResetHandleRef = $state(null);

    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);
    let allAnswered = $derived(
        clozes.length > 0 &&
            clozeAnswers.every((answer) => answer.trim() !== ""),
    );

    function checkAnswer() {
        if (allAnswered && !isSubmitting) {
            isSubmitting = true;
            submitAnswer({
                answers: clozeAnswers,
            });
        }
    }

    function handleClearAnswer() {
        clearAnswer();
        clozeAnswers = new Array(clozes.length).fill("");
    }

    function handleAnswerReset(payload) {
        const eventQuestionId = payload.question_id;
        const currentQuestionId =
            data?.id?.toString() || questionNumber?.toString();
        if (eventQuestionId === currentQuestionId) {
            clozeAnswers = new Array(clozes.length).fill("");
            isSubmitting = false;
        }
    }

    function handleAnswerSubmitted() {
        isSubmitting = false;
    }

    $effect(() => {
        if (live) {
            answerSubmittedHandleRef = live.handleEvent(
                "answer_submitted",
                handleAnswerSubmitted,
            );

            answerResetHandleRef = live.handleEvent(
                "answer_reset",
                handleAnswerReset,
            );

            return () => {
                if (live) {
                    live.removeHandleEvent(answerSubmittedHandleRef);
                    live.removeHandleEvent(answerResetHandleRef);
                }
            };
        }
    });

    function renderClozeText() {
        let text = processedText;
        let elements = [];
        let lastIndex = 0;

        clozes.forEach((cloze, index) => {
            const placeholder = cloze.placeholder;
            const placeholderIndex = text.indexOf(placeholder, lastIndex);

            if (placeholderIndex !== -1) {
                if (placeholderIndex > lastIndex) {
                    elements.push({
                        type: "text",
                        content: text.slice(lastIndex, placeholderIndex),
                    });
                }

                elements.push({
                    type: "input",
                    index: index,
                    cloze: cloze,
                });

                lastIndex = placeholderIndex + placeholder.length;
            }
        });

        if (lastIndex < text.length) {
            elements.push({
                type: "text",
                content: text.slice(lastIndex),
            });
        }

        return elements;
    }

    let textElements = $derived(renderClozeText());
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

    <div class="text-lg leading-relaxed text-base-content">
        {#each textElements as element}
            {#if element.type === "text"}
                <span>{element.content}</span>
            {:else if element.type === "input"}
                {@const userAnswerText = clozeAnswers[element.index]}
                {@const correctAnswer = data.answers[element.index]}
                {@const isCorrectAnswer =
                    isAnswered &&
                    userAnswerText.toLowerCase().trim() ===
                        correctAnswer.toLowerCase().trim()}
                {@const isIncorrectAnswer =
                    isAnswered &&
                    userAnswerText.trim() !== "" &&
                    !isCorrectAnswer}

                <span class="inline-block mx-2 relative">
                    <ClozeInput
                        bind:value={clozeAnswers[element.index]}
                        placeholder={element.cloze.hint ||
                            `Blank ${element.index + 1}`}
                        disabled={isAnswered}
                        style="width: {Math.max(
                            4,
                            correctAnswer ? correctAnswer.length + 2 : 6,
                        )}ch;"
                        class={isAnswered
                            ? isCorrectAnswer
                                ? "border-success text-success bg-success/5"
                                : isIncorrectAnswer
                                  ? "border-error text-error bg-error/5"
                                  : "border-base-300"
                            : ""}
                    />
                </span>
            {/if}
        {/each}
    </div>

    {#if !isAnswered}
        <div class="flex justify-start">
            <button
                class="btn btn-primary relative"
                disabled={!allAnswered || isSubmitting}
                onclick={checkAnswer}
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
        {@const correctCount = clozeAnswers.filter(
            (answer, i) =>
                answer.toLowerCase().trim() ===
                data.answers[i].toLowerCase().trim(),
        ).length}

        <div class="space-y-4">
            <!-- Summary -->
            <div
                class="p-4 rounded-lg {isCorrect
                    ? 'bg-success/10 border border-success/20'
                    : 'bg-base-100 border border-base-300'}"
            >
                <div class="flex items-center gap-3">
                    {#if isCorrect}
                        <svg
                            class="w-5 h-5 text-success"
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
                        <div class="font-medium text-success">
                            Perfect! All answers correct
                        </div>
                    {:else}
                        <svg
                            class="w-5 h-5 text-error"
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
                        <div class="font-medium text-error">
                            {correctCount} of {clozes.length} blanks correct
                        </div>
                    {/if}
                </div>
            </div>

            <!-- Answer Review Table -->
            {#if !isCorrect}
                <div class="overflow-x-auto">
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th class="w-16">Blank</th>
                                <th>Your Answer</th>
                                <th>Correct Answer</th>
                                <th class="w-20">Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each clozes as cloze, index}
                                {@const userAnswerText = clozeAnswers[index]}
                                {@const correctAnswer = data.answers[index]}
                                {@const isCorrectAnswer =
                                    userAnswerText.toLowerCase().trim() ===
                                    correctAnswer.toLowerCase().trim()}

                                <tr class="hover">
                                    <td>
                                        <div
                                            class="badge badge-neutral badge-sm"
                                        >
                                            {index + 1}
                                        </div>
                                    </td>
                                    <td>
                                        <span
                                            class="font-mono text-sm {isCorrectAnswer
                                                ? 'text-success'
                                                : 'text-error'}"
                                        >
                                            {userAnswerText || "(empty)"}
                                        </span>
                                    </td>
                                    <td>
                                        <span
                                            class="font-mono text-sm text-success"
                                        >
                                            {correctAnswer}
                                        </span>
                                    </td>
                                    <td>
                                        {#if isCorrectAnswer}
                                            <div
                                                class="badge badge-success badge-sm gap-1"
                                            >
                                                <svg
                                                    class="w-3 h-3"
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
                                            </div>
                                        {:else}
                                            <div
                                                class="badge badge-error badge-sm gap-1"
                                            >
                                                <svg
                                                    class="w-3 h-3"
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
                                                Wrong
                                            </div>
                                        {/if}
                                    </td>
                                </tr>
                            {/each}
                        </tbody>
                    </table>
                </div>
            {/if}
        </div>
    {/if}
</div>
