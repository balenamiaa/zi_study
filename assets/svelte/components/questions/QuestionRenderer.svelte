<script>
    import McqSingleQuestion from "./McqSingleQuestion.svelte";
    import McqMultiQuestion from "./McqMultiQuestion.svelte";
    import TrueFalseQuestion from "./TrueFalseQuestion.svelte";
    import ClozeQuestion from "./ClozeQuestion.svelte";
    import WrittenQuestion from "./WrittenQuestion.svelte";
    import EmqQuestion from "./EmqQuestion.svelte";

    let {
        question,
        questionNumber,
        isActive = false,
        userAnswer = null,
        live,
        userQuestionSets = null,
    } = $props();

    let questionType = $derived(question?.data?.question_type || "unknown");

    function submitAnswer(answerData) {
        live.pushEvent("answer_question", {
            question_id: question.id.toString(),
            answer: answerData,
        });
    }

    function clearAnswer() {
        live.pushEvent("clear_answer", {
            question_id: question.id.toString(),
        });
    }
</script>

<div
    class="question-container {isActive
        ? 'ring-1 md:ring-2 ring-primary shadow-lg'
        : ''} bg-base-200 rounded-md md:rounded-lg transition-all duration-300 border border-base-300"
>
    <div class="p-3 md:p-6">
        <!-- Question Content -->
        {#if questionType === "mcq_single"}
            <McqSingleQuestion
                data={question.data}
                {userAnswer}
                {submitAnswer}
                {clearAnswer}
                {questionNumber}
                {live}
                questionId={question.id}
                {userQuestionSets}
            />
        {:else if questionType === "mcq_multi"}
            <McqMultiQuestion
                data={question.data}
                {userAnswer}
                {submitAnswer}
                {clearAnswer}
                {questionNumber}
                {live}
                questionId={question.id}
                {userQuestionSets}
            />
        {:else if questionType === "true_false"}
            <TrueFalseQuestion
                data={question.data}
                {userAnswer}
                {submitAnswer}
                {clearAnswer}
                {questionNumber}
                {live}
                questionId={question.id}
                {userQuestionSets}
            />
        {:else if questionType === "cloze"}
            <ClozeQuestion
                data={question.data}
                {userAnswer}
                {submitAnswer}
                {clearAnswer}
                {questionNumber}
                {live}
                questionId={question.id}
                {userQuestionSets}
            />
        {:else if questionType === "written"}
            <WrittenQuestion
                data={question.data}
                {userAnswer}
                {submitAnswer}
                {clearAnswer}
                {questionNumber}
                {live}
                questionId={question.id}
                {userQuestionSets}
            />
        {:else if questionType === "emq"}
            <EmqQuestion
                data={question.data}
                {userAnswer}
                {submitAnswer}
                {clearAnswer}
                {questionNumber}
                {live}
                questionId={question.id}
                {userQuestionSets}
            />
        {:else}
            <div class="alert alert-warning">
                <svg
                    class="stroke-current shrink-0 h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.232 15.5c-.77.833.192 2.5 1.732 2.5z"
                    />
                </svg>
                <span>Unknown question type: {questionType}</span>
            </div>
        {/if}
    </div>
</div>
