<script>
    import {
        SearchIcon,
        PlusIcon,
        XIcon,
        CheckIcon,
        PencilIcon,
    } from "lucide-svelte";
    import VirtualList from "../components/VirtualList.svelte";
    import FilterPanel from "../components/questions/FilterPanel.svelte";
    import QuestionsOverview from "../components/questions/QuestionsOverview.svelte";
    import QuestionRenderer from "../components/questions/QuestionRenderer.svelte";
    import TagsManagementModal from "../components/questions/TagsManagementModal.svelte";
    import TextInput from "../components/TextInput.svelte";

    let {
        live,
        questionSetMeta,
        initialQuestions,
        initialAnswers,
        streamingState,
        currentUser,
        userQuestionSets,
    } = $props();

    let allQuestions = $state([...initialQuestions]);
    let allAnswers = $state([...initialAnswers]);
    let currentStreamingState = $state({ ...streamingState });
    let isEditingHeader = $state(false);
    let editingValues = $state({
        title: "",
        description: "",
        is_private: false,
    });

    let searchQuery = $state("");
    let showFilters = $state(false);
    let difficultyRange = $state([1, 5]);
    let answerStatus = $state("all");
    let showTagsModal = $state(false);

    let currentQuestionIndex = $state(0);
    let isDraggingSlider = $state(false);
    let questionsContainer = $state();
    let virtualList = $state();
    let questionObserver = $state();
    let loadingObserver = $state();

    const answerLookup = $derived(
        new Map(allAnswers.map((answer) => [answer.question_id, answer])),
    );

    const questionSet = $derived({
        ...questionSetMeta,
        questions: allQuestions,
        answers: allAnswers,
    });

    const filteredQuestions = $derived.by(() => {
        if (!allQuestions) return [];

        const searchLower = searchQuery.toLowerCase();

        return allQuestions.filter((q) => {
            const matchesSearch =
                searchQuery === "" ||
                q.data.question_text?.toLowerCase().includes(searchLower);

            const difficulty = parseInt(q.data.difficulty) || 3;
            const matchesDifficulty =
                difficulty >= difficultyRange[0] &&
                difficulty <= difficultyRange[1];

            const hasAnswer = answerLookup.has(q.id);
            const matchesAnswerStatus =
                answerStatus === "all" ||
                (answerStatus === "answered" && hasAnswer) ||
                (answerStatus === "unanswered" && !hasAnswer);

            return matchesSearch && matchesDifficulty && matchesAnswerStatus;
        });
    });

    const virtualListItems = $derived.by(() => {
        const items = [...filteredQuestions];
        if (currentStreamingState?.has_more) {
            items.push({ isLoadingTrigger: true });
        }
        return items;
    });

    function handleFieldUpdate(field, value) {
        live.pushEvent("update_question_set", { field, value });
    }

    function startHeaderEdit() {
        if (questionSet?.owner?.email !== currentUser?.email) return;
        editingValues = {
            title: questionSet.title || "",
            description: questionSet.description || "",
            is_private: questionSet.is_private || false,
        };
        isEditingHeader = true;
    }

    function cancelHeaderEdit() {
        isEditingHeader = false;
    }

    function saveHeaderChanges() {
        if (editingValues.title !== questionSet.title) {
            handleFieldUpdate("title", editingValues.title);
        }
        if (editingValues.description !== questionSet.description) {
            handleFieldUpdate("description", editingValues.description);
        }
        if (editingValues.is_private !== questionSet.is_private) {
            handleFieldUpdate("is_private", editingValues.is_private);
        }
        isEditingHeader = false;
    }

    function handleSliderChange(index) {
        isDraggingSlider = true;
        currentQuestionIndex = index;
        if (virtualList) {
            virtualList.scrollToIndex(index, { behavior: "smooth" });
        }
        setTimeout(() => {
            isDraggingSlider = false;
        }, 500);
    }

    function observeQuestionElement(element, index) {
        element.dataset.index = String(index);
        questionObserver?.observe(element);
        return {
            destroy() {
                questionObserver?.unobserve(element);
            },
        };
    }

    function observeLoadingTrigger(element) {
        loadingObserver?.observe(element);
        return {
            destroy() {
                loadingObserver?.unobserve(element);
            },
        };
    }

    $effect(() => {
        if (!live) return;

        const handles = [
            live.handleEvent("questions_chunk_received", (event) => {
                allQuestions = [...allQuestions, ...event.questions];
                allAnswers = [...allAnswers, ...event.answers];
                currentStreamingState = event.streaming_state;
            }),
            live.handleEvent("answer_updated", (event) => {
                const index = allAnswers.findIndex(
                    (a) => a.question_id === event.answer.question_id,
                );
                if (index > -1) {
                    allAnswers[index] = event.answer;
                } else {
                    allAnswers = [...allAnswers, event.answer];
                }
            }),
            live.handleEvent("answer_reset", (event) => {
                allAnswers = allAnswers.filter(
                    (a) => a.question_id !== event.question_id,
                );
            }),
            live.handleEvent("question_set_meta_updated", (event) => {
                questionSetMeta[event.field] = event.value;
            }),
        ];

        return () => handles.forEach((h) => live.removeHandleEvent(h));
    });

    let hasStartedStreaming = $state(false);
    $effect(() => {
        if (
            live &&
            !hasStartedStreaming &&
            currentStreamingState.has_more &&
            !currentStreamingState.is_streaming
        ) {
            hasStartedStreaming = true;
            live.pushEvent("start_streaming", {});
        }
    });

    $effect(() => {
        if (!questionsContainer) return;

        questionObserver = new IntersectionObserver(
            (entries) => {
                if (isDraggingSlider) return;

                let mostVisibleEntry = null;
                for (const entry of entries) {
                    if (entry.isIntersecting) {
                        if (
                            !mostVisibleEntry ||
                            entry.intersectionRatio >
                                mostVisibleEntry.intersectionRatio
                        ) {
                            mostVisibleEntry = entry;
                        }
                    }
                }

                if (mostVisibleEntry) {
                    const index = parseInt(
                        mostVisibleEntry.target.dataset.index,
                    );
                    if (
                        index !== currentQuestionIndex &&
                        mostVisibleEntry.intersectionRatio > 0.3
                    ) {
                        currentQuestionIndex = index;
                    }
                }
            },
            {
                root: questionsContainer,
                rootMargin: "-20% 0px -20% 0px",
                threshold: [0, 0.1, 0.3, 0.5, 0.7, 0.9],
            },
        );

        loadingObserver = new IntersectionObserver(
            (entries) => {
                if (
                    entries[0]?.isIntersecting &&
                    currentStreamingState.has_more &&
                    !currentStreamingState.is_streaming
                ) {
                    live.pushEvent("request_more_questions", {});
                }
            },
            { root: questionsContainer, rootMargin: "200px" },
        );

        return () => {
            questionObserver?.disconnect();
            loadingObserver?.disconnect();
        };
    });
</script>

<div class="min-h-screen bg-base-100 flex flex-col gap-4">
    <div class="bg-base-200 border-b border-base-300">
        <div class="max-w-8xl mx-auto p-2 md:p-4">
            {#if isEditingHeader}
                <div
                    class="bg-base-100 rounded-lg p-4 border border-base-300 space-y-4"
                >
                    <div
                        class="flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                    >
                        <h3 class="text-lg font-semibold text-base-content">
                            Edit Question Set
                        </h3>
                        <div class="flex items-center gap-2">
                            <button
                                class="btn btn-ghost btn-sm gap-2"
                                onclick={cancelHeaderEdit}
                            >
                                <XIcon class="h-4 w-4" />
                                Cancel
                            </button>
                            <button
                                class="btn btn-primary btn-sm gap-2"
                                onclick={saveHeaderChanges}
                            >
                                <CheckIcon class="h-4 w-4" />
                                Save Changes
                            </button>
                        </div>
                    </div>
                    <div class="space-y-4">
                        <div>
                            <label
                                for="title"
                                class="block text-sm font-medium text-base-content mb-2"
                                >Title</label
                            >
                            <input
                                id="title"
                                type="text"
                                bind:value={editingValues.title}
                                placeholder="Question Set Title"
                                class="input input-bordered w-full text-2xl font-bold"
                            />
                        </div>
                        <div>
                            <label
                                for="description"
                                class="block text-sm font-medium text-base-content mb-2"
                                >Description</label
                            >
                            <textarea
                                id="description"
                                bind:value={editingValues.description}
                                placeholder="Add a description..."
                                class="textarea textarea-bordered w-full"
                                rows="3"
                            ></textarea>
                        </div>
                        <div>
                            <label
                                for="is_private"
                                class="block text-sm font-medium text-base-content mb-2"
                                >Visibility</label
                            >
                            <div class="form-control">
                                <label
                                    class="cursor-pointer label justify-start gap-3"
                                >
                                    <input
                                        id="is_private"
                                        type="checkbox"
                                        bind:checked={editingValues.is_private}
                                        class="toggle toggle-primary"
                                    />
                                    <span class="label-text font-medium">
                                        {editingValues.is_private
                                            ? "Private Set"
                                            : "Public Set"}
                                    </span>
                                </label>
                            </div>
                        </div>
                    </div>
                </div>
            {:else}
                <div class="space-y-4 relative">
                    {#if questionSet?.owner && questionSet.owner.email === currentUser?.email}
                        <button
                            class="btn btn-outline btn-xs gap-1 absolute top-0 right-0 z-10"
                            onclick={startHeaderEdit}
                        >
                            <PencilIcon class="h-3 w-3" />
                            <span class="hidden sm:inline">Edit</span>
                        </button>
                    {/if}

                    <div class="pr-16 sm:pr-20">
                        <div class="mb-3">
                            <h1
                                class="text-2xl sm:text-3xl font-bold text-base-content break-words"
                            >
                                {questionSet.title || "Untitled Question Set"}
                            </h1>
                        </div>
                        <div
                            class="flex flex-col sm:flex-row sm:items-center gap-3 sm:gap-4 mb-3"
                        >
                            {#if questionSet?.owner}
                                <div class="flex items-center gap-2">
                                    <div
                                        class="w-6 h-6 bg-gradient-to-br from-primary to-secondary rounded-full flex items-center justify-center"
                                    >
                                        <span
                                            class="text-xs font-bold text-primary-content"
                                        >
                                            {questionSet.owner.email
                                                .charAt(0)
                                                .toUpperCase()}
                                        </span>
                                    </div>
                                    <span
                                        class="text-sm text-base-content/70 font-medium"
                                    >
                                        by {questionSet.owner.email}
                                    </span>
                                </div>
                            {/if}
                            <div class="flex items-center gap-2">
                                <div
                                    class="badge badge-sm {questionSet.is_private
                                        ? 'badge-secondary'
                                        : 'badge-primary'} font-medium"
                                >
                                    {questionSet.is_private
                                        ? "Private"
                                        : "Public"}
                                </div>
                            </div>
                        </div>
                        {#if questionSet.description}
                            <div
                                class="text-base-content/70 text-sm sm:text-base break-words"
                            >
                                {questionSet.description}
                            </div>
                        {:else}
                            <div class="text-base-content/50 italic text-sm">
                                No description provided
                            </div>
                        {/if}
                    </div>
                    <div class="flex items-center gap-2 flex-wrap">
                        {#if questionSet?.tags && questionSet.tags.length > 0}
                            {#each questionSet.tags as tag}
                                <span class="badge badge-outline text-xs"
                                    >{tag.name}</span
                                >
                            {/each}
                        {:else}
                            <span class="text-base-content/50 text-sm"
                                >No tags</span
                            >
                        {/if}
                        {#if questionSet?.owner && questionSet.owner.email === currentUser?.email}
                            <button
                                class="btn btn-ghost btn-circle btn-xs hover:bg-primary hover:text-primary-content transition-colors"
                                onclick={() => (showTagsModal = true)}
                                title="Manage tags"
                            >
                                <PlusIcon class="h-3 w-3" />
                            </button>
                        {/if}
                    </div>
                </div>
            {/if}
        </div>
    </div>

    <div class="bg-base-100 border-b border-base-300">
        <div class="max-w-8xl mx-auto p-2 md:p-4">
            <div
                class="flex flex-col lg:flex-row gap-4 items-start lg:items-center"
            >
                <div class="flex-1 w-full lg:max-w-lg">
                    <TextInput
                        bind:value={searchQuery}
                        placeholder="Search questions..."
                        fullWidth={true}
                        size="lg"
                        variant="bordered"
                        icon={SearchIcon}
                        type="search"
                    />
                </div>
                <div
                    class="flex flex-col sm:flex-row items-start sm:items-center gap-4 w-full lg:w-auto"
                >
                    <button
                        class="btn btn-outline gap-2 w-full sm:w-auto"
                        onclick={() => (showFilters = !showFilters)}
                    >
                        <svg
                            class="w-4 h-4"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            ><path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.414A1 1 0 013 6.707V4z"
                            /></svg
                        >
                        Filters
                        {#if showFilters}
                            <svg
                                class="w-4 h-4"
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                ><path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M5 15l7-7 7 7"
                                /></svg
                            >
                        {:else}
                            <svg
                                class="w-4 h-4"
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                ><path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M19 9l-7 7-7-7"
                                /></svg
                            >
                        {/if}
                    </button>

                    <div class="text-sm text-base-content/70 whitespace-nowrap">
                        {filteredQuestions.length} of {currentStreamingState?.total_count ||
                            0} questions
                        {#if currentStreamingState?.loaded_count && currentStreamingState.loaded_count < currentStreamingState.total_count}
                            <span class="text-primary"
                                >({currentStreamingState.loaded_count} loaded)</span
                            >
                        {/if}
                    </div>
                </div>
            </div>

            {#if showFilters}
                <div
                    class="mt-4 bg-base-200 rounded-lg p-4 border border-base-300"
                >
                    <FilterPanel bind:difficultyRange bind:answerStatus />
                </div>
            {/if}
        </div>
    </div>

    {#if questionSet}
        <QuestionsOverview
            {questionSet}
            {filteredQuestions}
            bind:currentQuestionIndex
            {handleSliderChange}
            loadingState={currentStreamingState}
        />
    {/if}

    <div
        bind:this={questionsContainer}
        class="h-[70vh] p-3 md:mx-2 lg:mx-4 bg-primary/3 rounded-lg shadow-2xl ring-1 ring-base-300/50 backdrop-blur-sm"
    >
        <div class="max-w-8xl mx-auto h-full">
            {#if filteredQuestions.length === 0 && !currentStreamingState?.is_streaming}
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
                            ><path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                            /></svg
                        >
                    </div>
                    <h3 class="text-xl font-semibold text-base-content mb-2">
                        No questions found
                    </h3>
                    <p class="text-base-content/60">
                        Try adjusting your search or filter criteria.
                    </p>
                </div>
            {:else}
                <VirtualList
                    bind:this={virtualList}
                    items={virtualListItems}
                    estimatedItemHeight={350}
                    height="100%"
                >
                    {#snippet children(item, index)}
                        {#if item.isLoadingTrigger}
                            <div class="w-full py-8" use:observeLoadingTrigger>
                                {#if currentStreamingState?.is_streaming}
                                    <div class="text-center">
                                        <div
                                            class="loading loading-spinner loading-lg text-primary"
                                        ></div>
                                        <p class="text-base-content/60 mt-4">
                                            Streaming in progress...
                                        </p>
                                    </div>
                                {:else}
                                    <div class="text-center">
                                        <button
                                            class="btn btn-outline btn-lg gap-2"
                                            onclick={() =>
                                                live.pushEvent(
                                                    "request_more_questions",
                                                    {},
                                                )}
                                        >
                                            <svg
                                                class="w-5 h-5"
                                                fill="none"
                                                stroke="currentColor"
                                                viewBox="0 0 24 24"
                                                ><path
                                                    stroke-linecap="round"
                                                    stroke-linejoin="round"
                                                    stroke-width="2"
                                                    d="M19 14l-7 7m0 0l-7-7m7 7V3"
                                                ></path></svg
                                            >
                                            Load More Questions
                                        </button>
                                    </div>
                                {/if}
                            </div>
                        {:else}
                            {@const question = item}
                            {@const userAnswer = answerLookup.get(question.id)}
                            <div class="p-3" use:observeQuestionElement={index}>
                                <QuestionRenderer
                                    {question}
                                    questionNumber={index + 1}
                                    isActive={index === currentQuestionIndex}
                                    {userAnswer}
                                    {live}
                                    {userQuestionSets}
                                />
                            </div>
                        {/if}
                    {/snippet}
                </VirtualList>
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
