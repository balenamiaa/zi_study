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
    } = $props();

    // Parse the cloze text to get cloze information
    let { clozes, processedText } = parseClozeText(data.question_text);

    console.log(userAnswer);

    let clozeAnswers = $state(
        userAnswer?.data?.answers || new Array(clozes.length).fill(""),
    );

    let showExplanation = $state(false);
    let isAnswered = $derived(userAnswer !== null && userAnswer !== undefined);

    // Check if all clozes are filled
    let allAnswered = $derived(
        clozes.length > 0 &&
            clozeAnswers.every((answer) => answer.trim() !== ""),
    );

    function checkAnswer() {
        if (allAnswered) {
            submitAnswer({
                answers: clozeAnswers,
            });
        }
    }

    function handleClearAnswer() {
        clearAnswer();
        clozeAnswers = new Array(clozes.length).fill("");
    }

    // Render the text with input fields
    function renderClozeText() {
        let text = processedText;
        let elements = [];
        let lastIndex = 0;

        clozes.forEach((cloze, index) => {
            const placeholder = cloze.placeholder;
            const placeholderIndex = text.indexOf(placeholder, lastIndex);

            if (placeholderIndex !== -1) {
                // Add text before placeholder
                if (placeholderIndex > lastIndex) {
                    elements.push({
                        type: "text",
                        content: text.slice(lastIndex, placeholderIndex),
                    });
                }

                // Add cloze input
                elements.push({
                    type: "input",
                    index: index,
                    cloze: cloze,
                });

                lastIndex = placeholderIndex + placeholder.length;
            }
        });

        // Add remaining text
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
        {#if data.explanation}
            <ExplanationPanel explanation={data.explanation} />
        {/if}
    </QuestionToolbar>

    <!-- Question Text with Cloze Inputs -->
    <div class="text-lg leading-relaxed text-base-content">
        {#each textElements as element}
            {#if element.type === "text"}
                <span>{element.content}</span>
            {:else if element.type === "input"}
                <span class="inline-block mx-1">
                    <ClozeInput
                        bind:value={clozeAnswers[element.index]}
                        placeholder={element.cloze.hint ||
                            `Blank ${element.index + 1}`}
                        disabled={isAnswered}
                        style="width: {Math.max(
                            4,
                            element.cloze.answer.length + 2,
                        )}ch;"
                    />
                </span>
            {/if}
        {/each}
    </div>

    <!-- Submit Button -->
    {#if !isAnswered}
        <div class="flex justify-start">
            <button
                class="btn btn-primary"
                disabled={!allAnswered}
                onclick={checkAnswer}
            >
                Check Answer
            </button>
        </div>
    {/if}
</div>
