<script>
    import FilterPanel from "../components/FilterPanel.svelte";
    import QuestionsOverview from "../components/QuestionsOverview.svelte";
    import QuestionRenderer from "../components/QuestionRenderer.svelte";

    let { live, questionSet } = $props();

    // State for filtering and searching
    let searchQuery = $state("");
    let showFilters = $state(false);
    let difficultyRange = $state([1, 5]);
    let answerStatus = $state("all"); // 'all', 'answered', 'unanswered'
    let currentQuestionIndex = $state(0);

    // Questions container reference for scrolling
    let questionsContainer;

    // Filtered questions based on search and filters
    let filteredQuestions = $derived.by(() => {
        if (!questionSet?.questions) return [];

        return questionSet.questions.filter((question) => {
            // Search filter
            const matchesSearch =
                searchQuery === "" ||
                question.data.question_text
                    ?.toLowerCase()
                    .includes(searchQuery.toLowerCase());

            // Difficulty filter
            const difficulty = parseInt(question.data.difficulty) || 3;
            const matchesDifficulty =
                difficulty >= difficultyRange[0] &&
                difficulty <= difficultyRange[1];

            // Answer status filter (for now, treating all as unanswered since we don't have user answers yet)
            const matchesAnswerStatus =
                answerStatus === "all" || answerStatus === "unanswered"; // For demo purposes

            return matchesSearch && matchesDifficulty && matchesAnswerStatus;
        });
    });

    // Function to handle slider change
    function handleSliderChange(index) {
        currentQuestionIndex = index;
        scrollToQuestion(index);
    }

    // Function to scroll to specific question
    function scrollToQuestion(index) {
        if (questionsContainer && filteredQuestions[index]) {
            // Find the specific question element within the container
            const questionsWrapper = questionsContainer.children[0]; // max-w-4xl mx-auto div
            if (questionsWrapper && questionsWrapper.children[index]) {
                const questionElement = questionsWrapper.children[index];

                // Calculate the position relative to the container
                const containerRect =
                    questionsContainer.getBoundingClientRect();
                const elementRect = questionElement.getBoundingClientRect();
                const relativeTop =
                    elementRect.top -
                    containerRect.top +
                    questionsContainer.scrollTop;

                // Scroll within the container
                questionsContainer.scrollTo({
                    top: relativeTop - 20, // 20px offset for better visibility
                    behavior: "smooth",
                });
            }
        }
    }

    console.log("Question Set:", questionSet);
</script>

<div class="min-h-screen bg-base-100 flex flex-col">
    <!-- Header -->
    <div class="bg-base-200 border-b border-base-300">
        <div class="max-w-7xl mx-auto p-4 md:p-6">
            <div class="flex items-start justify-between mb-4">
                <div>
                    <h1 class="text-3xl font-bold text-base-content">
                        {questionSet?.title || "Loading..."}
                    </h1>
                    {#if questionSet?.description}
                        <p class="text-base-content/70 mt-2">
                            {questionSet.description}
                        </p>
                    {/if}
                </div>

                {#if questionSet?.is_private}
                    <div class="badge badge-secondary">Private</div>
                {:else}
                    <div class="badge badge-primary">Public</div>
                {/if}
            </div>

            <!-- Tags -->
            {#if questionSet?.tags && questionSet.tags.length > 0}
                <div class="flex flex-wrap gap-2">
                    {#each questionSet.tags as tag}
                        <span class="badge badge-outline">{tag.name}</span>
                    {/each}
                </div>
            {/if}
        </div>
    </div>

    <!-- Search and Filters -->
    <div class="bg-base-100 border-b border-base-300">
        <div class="max-w-7xl mx-auto p-4 md:p-6">
            <div
                class="flex flex-col sm:flex-row gap-4 items-start sm:items-center"
            >
                <!-- Search -->
                <div class="relative flex-1 max-w-md">
                    <div
                        class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
                    >
                        <svg
                            class="h-5 w-5 text-base-content/40"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                            />
                        </svg>
                    </div>
                    <input
                        type="text"
                        bind:value={searchQuery}
                        placeholder="Search questions..."
                        class="input input-bordered w-full pl-10 transition-all duration-200 focus:shadow-md"
                    />
                </div>

                <!-- Filters Button -->
                <button
                    class="btn btn-outline gap-2 min-w-fit"
                    onclick={() => (showFilters = !showFilters)}
                >
                    <svg
                        class="w-4 h-4"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.414A1 1 0 013 6.707V4z"
                        />
                    </svg>
                    All Filters
                    {#if showFilters}
                        <svg
                            class="w-4 h-4"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M5 15l7-7 7 7"
                            />
                        </svg>
                    {:else}
                        <svg
                            class="w-4 h-4"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M19 9l-7 7-7-7"
                            />
                        </svg>
                    {/if}
                </button>

                <!-- Results count -->
                <div class="text-sm text-base-content/70 min-w-fit">
                    {filteredQuestions.length} of {questionSet?.questions
                        ?.length || 0} questions
                </div>
            </div>

            <!-- Filter Panel -->
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

    <!-- Questions Container -->
    <div class="flex-1 overflow-hidden">
        <div
            bind:this={questionsContainer}
            class="h-full overflow-y-auto px-4 md:px-6 py-6 space-y-6 scroll-smooth"
        >
            <div class="max-w-4xl mx-auto">
                {#if filteredQuestions.length === 0}
                    <div class="text-center py-16">
                        <div
                            class="w-24 h-24 mx-auto mb-4 bg-base-200 rounded-full flex items-center justify-center"
                        >
                            <svg
                                class="w-12 h-12 text-base-content/30"
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                                />
                            </svg>
                        </div>
                        <h3
                            class="text-xl font-semibold text-base-content mb-2"
                        >
                            No questions found
                        </h3>
                        <p class="text-base-content/60">
                            Try adjusting your search or filter criteria.
                        </p>
                    </div>
                {:else}
                    {#each filteredQuestions as question, index (question.id)}
                        {@const userAnswer = questionSet?.answers?.find(
                            (a) => a.question_id === question.id,
                        )}
                        <div class="mb-8">
                            <QuestionRenderer
                                {question}
                                questionNumber={index + 1}
                                isActive={index === currentQuestionIndex}
                                {userAnswer}
                                {live}
                            />
                        </div>
                    {/each}
                {/if}
            </div>
        </div>
    </div>
</div>
