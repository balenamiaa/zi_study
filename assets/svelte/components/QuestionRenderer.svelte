<script>
    import McqSingleQuestion from './questions/McqSingleQuestion.svelte';
    import McqMultiQuestion from './questions/McqMultiQuestion.svelte';
    import TrueFalseQuestion from './questions/TrueFalseQuestion.svelte';
    import ClozeQuestion from './questions/ClozeQuestion.svelte';
    import WrittenQuestion from './questions/WrittenQuestion.svelte';
    
    let { question, questionNumber, isActive = false, userAnswer = null, live } = $props();
    
    // Get the question type
    let questionType = $derived(question?.data?.question_type || 'unknown');
    
    // Function to submit answer to backend
    function submitAnswer(answerData) {
        live.pushEvent("answer_question", {
            question_id: question.id.toString(),
            answer: answerData
        });
    }

    function clearAnswer() {
        live.pushEvent("clear_answer", {
            question_id: question.id.toString()
        });
    }
</script>

<div class="question-container {isActive ? 'ring-2 ring-primary' : ''} bg-base-200 rounded-lg transition-all duration-300">
    <div class="p-6">
        <!-- Question Header -->
        <div class="flex items-center justify-between mb-4">
            <div class="flex items-center gap-3">
                <div class="w-8 h-8 bg-primary text-primary-content rounded-full flex items-center justify-center text-sm font-bold">
                    {questionNumber}
                </div>
                <div>
                    <span class="badge badge-outline badge-sm capitalize">
                        {questionType.replace('_', ' ')}
                    </span>
                    {#if question?.data?.difficulty}
                        <span class="badge badge-secondary badge-sm ml-2">
                            Level {question.data.difficulty}
                        </span>
                    {/if}
                </div>
            </div>
            
            {#if isActive}
                <div class="badge badge-primary">Current</div>
            {/if}
        </div>
        
        <!-- Question Content -->
        {#if questionType === 'mcq_single'}
            <McqSingleQuestion data={question.data} {userAnswer} {submitAnswer} {clearAnswer} />
        {:else if questionType === 'mcq_multi'}
            <McqMultiQuestion data={question.data} {userAnswer} {submitAnswer} {clearAnswer} />
        {:else if questionType === 'true_false'}
            <TrueFalseQuestion data={question.data} {userAnswer} {submitAnswer} {clearAnswer} />
        {:else if questionType === 'cloze'}
            <ClozeQuestion data={question.data} {userAnswer} {submitAnswer} {clearAnswer} />
        {:else if questionType === 'written'}
            <WrittenQuestion data={question.data} {userAnswer} {submitAnswer} {clearAnswer} />
        {:else}
            <div class="alert alert-warning">
                <svg class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.232 15.5c-.77.833.192 2.5 1.732 2.5z" />
                </svg>
                <span>Unknown question type: {questionType}</span>
            </div>
        {/if}
        
        <!-- Question Footer - Retention Aid only shows if question is answered -->
        <!-- This will be implemented when we integrate with user answers -->
    </div>
</div> 