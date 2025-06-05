<script>
        import { SearchIcon, PlusIcon } from "lucide-svelte";
    import FilterPanel from "../components/questions/FilterPanel.svelte";
    import QuestionsOverview from "../components/questions/QuestionsOverview.svelte";
    import QuestionRenderer from "../components/questions/QuestionRenderer.svelte";
    import InlineEdit from "../components/InlineEdit.svelte";
    import TagsManagementModal from "../components/questions/TagsManagementModal.svelte";
    let { live, questionSet, userQuestionSets, currentUser } = $props();

        let searchQuery = $state("");
    let showFilters = $state(false);
    let difficultyRange = $state([1, 5]);
    let answerStatus = $state("all");
    let currentQuestionIndex = $state(0);
    let showTagsModal = $state(false);

    let questionsContainer;
    let filteredQuestions = $derived.by(() => {
        if (!questionSet?.questions) return [];

        return questionSet.questions.filter((question) => {
                        const matchesSearch =
                searchQuery === "" ||
                question.data.question_text
                    ?.toLowerCase()
                    .includes(searchQuery.toLowerCase());

            const difficulty = parseInt(question.data.difficulty) || 3;
            const matchesDifficulty =
                difficulty >= difficultyRange[0] &&
                difficulty <= difficultyRange[1];

            const matchesAnswerStatus =
                answerStatus === "all" || answerStatus === "unanswered";

            return matchesSearch && matchesDifficulty && matchesAnswerStatus;
        });
    });

    function handleSliderChange(index) {
        currentQuestionIndex = index;
        scrollToQuestion(index);
    }
    function scrollToQuestion(index) {
        if (questionsContainer && filteredQuestions[index]) {
            const questionsWrapper = questionsContainer.children[0];
            if (questionsWrapper && questionsWrapper.children[index]) {
                const questionElement = questionsWrapper.children[index];
                const containerRect = questionsContainer.getBoundingClientRect();
                const elementRect = questionElement.getBoundingClientRect();
                const relativeTop = elementRect.top - containerRect.top + questionsContainer.scrollTop;

                questionsContainer.scrollTo({
                    top: relativeTop - 20,
                    behavior: "smooth",
                });
            }
        }
    }

    function detectCurrentQuestion() {
        if (!questionsContainer || filteredQuestions.length === 0) return;

        const containerRect = questionsContainer.getBoundingClientRect();
        const containerMidpoint = containerRect.top + containerRect.height / 2;
        const questionsWrapper = questionsContainer.children[0];
        if (!questionsWrapper) return;

        let closestIndex = 0;
        let closestDistance = Infinity;

        for (let i = 0; i < questionsWrapper.children.length; i++) {
            const questionElement = questionsWrapper.children[i];
            const questionRect = questionElement.getBoundingClientRect();
            const questionMidpoint = questionRect.top + questionRect.height / 2;
            const distance = Math.abs(questionMidpoint - containerMidpoint);

            if (distance < closestDistance) {
                closestDistance = distance;
                closestIndex = i;
            }
        }

        if (closestIndex !== currentQuestionIndex) {
            currentQuestionIndex = closestIndex;
        }
    }

    let scrollTimeout;
    function handleScroll() {
        clearTimeout(scrollTimeout);
        scrollTimeout = setTimeout(detectCurrentQuestion, 100);
    }

    function handleFieldUpdate(field, value) {
        live.pushEvent("update_question_set", { field, value });
    }
</script>

    <div class="min-h-screen bg-base-100 flex flex-col gap-4">
    <div class="bg-base-200 border-b border-base-300">
        <div class="max-w-7xl mx-auto p-2 md:p-4">
            <div class="flex items-start justify-between mb-4">
                <div class="flex-1 mr-4">
                    <div class="mb-2">
                        <InlineEdit
                            bind:value={questionSet.title}
                            placeholder="Question Set Title"
                            type="text"
                            disabled={!questionSet?.owner || questionSet.owner.email !== currentUser?.email}
                            onSave={(value) => handleFieldUpdate("title", value)}
                            class="text-3xl font-bold text-base-content"
                        />
                    </div>

                    <div class="mt-2">
                        <InlineEdit
                            bind:value={questionSet.description}
                            placeholder="Add a description..."
                            type="textarea"
                            disabled={!questionSet?.owner || questionSet.owner.email !== currentUser?.email}
                            onSave={(value) => handleFieldUpdate("description", value)}
                            class="text-base-content/70"
                        />
                    </div>
                </div>

                <div class="flex flex-col items-end gap-2">
                    <InlineEdit
                        bind:value={questionSet.is_private}
                        type="boolean"
                        disabled={!questionSet?.owner || questionSet.owner.email !== currentUser?.email}
                        onSave={(value) => handleFieldUpdate("is_private", value)}
                    />
                    
                    {#if questionSet?.owner}
                        <div class="text-xs text-base-content/50">
                            by {questionSet.owner.email}
                        </div>
                    {/if}
                </div>
            </div>

            <div class="flex items-center gap-2">
                {#if questionSet?.tags && questionSet.tags.length > 0}
                    <div class="flex flex-wrap gap-2">
                        {#each questionSet.tags as tag}
                            <span class="badge badge-outline">{tag.name}</span>
                        {/each}
                    </div>
                {:else}
                    <span class="text-base-content/50 text-sm">No tags</span>
                {/if}
                
                {#if questionSet?.owner && questionSet.owner.email === currentUser?.email}
                    <button
                        class="btn btn-ghost btn-circle btn-xs ml-1 hover:bg-primary hover:text-primary-content transition-colors"
                        onclick={() => (showTagsModal = true)}
                        title="Manage tags"
                    >
                        <PlusIcon class="h-3 w-3" />
                    </button>
                {/if}
            </div>
        </div>
    </div>

    <div class="bg-base-100 border-b border-base-300">
        <div class="max-w-7xl mx-auto p-2 md:p-4">
            <div class="flex flex-col sm:flex-row gap-4 items-start sm:items-center">
                <label for="search" class="input relative flex-1 max-w-md">
                    <SearchIcon class="h-5 w-5" />
                    <input
                        type="search"
                        bind:value={searchQuery}
                        placeholder="Search questions..."
                        class="grow"
                    />
                </label>

                <button
                    class="btn btn-outline gap-2 min-w-fit"
                    onclick={() => (showFilters = !showFilters)}
                >
                    <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.414A1 1 0 013 6.707V4z" />
                    </svg>
                    All Filters
                    {#if showFilters}
                        <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                        </svg>
                    {:else}
                        <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                        </svg>
                    {/if}
                </button>

                <div class="text-sm text-base-content/70 min-w-fit">
                    {filteredQuestions.length} of {questionSet?.questions?.length || 0} questions
                </div>
            </div>

            {#if showFilters}
                <div class="mt-4 border-t border-base-300 pt-4">
                    <FilterPanel bind:difficultyRange bind:answerStatus />
                </div>
            {/if}
        </div>
    </div>

    <!-- Questions Overview -->
    {#if questionSet}
        <QuestionsOverview
            {questionSet}
            {filteredQuestions}
            bind:currentQuestionIndex
            {handleSliderChange}
        />
    {/if}

    <div
        bind:this={questionsContainer}
        onscroll={handleScroll}
        class="h-[70vh] overflow-y-auto p-3 md:mx-4 lg:mx-8 space-y-3 scroll-smooth pb-64 bg-primary/3 rounded-lg shadow-2xl ring-1 ring-base-300/50 backdrop-blur-sm"
    >
        <div class="max-w-4xl mx-auto">
            {#if filteredQuestions.length === 0}
                <div class="text-center py-16">
                    <div class="w-24 h-24 mx-auto mb-4 bg-base-200 rounded-full flex items-center justify-center">
                        <svg class="w-12 h-12 text-base-content/30" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </div>
                    <h3 class="text-xl font-semibold text-base-content mb-2">No questions found</h3>
                    <p class="text-base-content/60">Try adjusting your search or filter criteria.</p>
                </div>
            {:else}
                {#each filteredQuestions as question, index (question.id)}
                    {@const userAnswer = questionSet?.answers?.find((a) => a.question_id === question.id)}
                    <div class="mb-8">
                        <QuestionRenderer
                            {question}
                            questionNumber={index + 1}
                            isActive={index === currentQuestionIndex}
                            {userAnswer}
                            {live}
                            {userQuestionSets}
                        />
                    </div>
                {/each}
            {/if}
        </div>
    </div>
</div>

<TagsManagementModal
    isOpen={showTagsModal}
    onClose={() => (showTagsModal = false)}
    questionSetId={questionSet?.id}
    currentTags={questionSet?.tags || []}
    {live}
/>
