<script>
    let {
        items = [],
        estimatedItemHeight = 250,
        height = "100%",
        onscroll = () => {},
        class: className = "",
        overscan = 2,
        children,
    } = $props();

    let scrollContainer = $state();
    let scrollTop = $state(0);
    let containerHeight = $state(0);
    let mounted = $state(false);
    let itemHeights = $state(new Map());
    let totalHeight = $state(0);
    let itemOffsets = $state([]);

    function calculateOffsets() {
        const offsets = [0];
        let runningTotal = 0;

        for (let i = 0; i < items.length; i++) {
            const height = itemHeights.get(i) || estimatedItemHeight;
            runningTotal += height;
            offsets.push(runningTotal);
        }

        itemOffsets = offsets;
        totalHeight = runningTotal;
    }

    $effect(() => {
        calculateOffsets();
    });

    let visibleRange = $derived.by(() => {
        if (!mounted || containerHeight === 0 || items.length === 0) {
            return { start: 0, end: Math.min(10, items.length) };
        }

        let start = 0;
        let end = items.length;

        for (let i = 0; i < itemOffsets.length - 1; i++) {
            if (itemOffsets[i + 1] > scrollTop) {
                start = Math.max(0, i - overscan);
                break;
            }
        }

        const viewportBottom = scrollTop + containerHeight;
        for (let i = start; i < itemOffsets.length - 1; i++) {
            if (itemOffsets[i] > viewportBottom) {
                end = Math.min(items.length, i + overscan);
                break;
            }
        }

        return { start, end };
    });

    let visibleItems = $derived(
        items.slice(visibleRange.start, visibleRange.end).map((item, index) => {
            const actualIndex = visibleRange.start + index;
            return {
                item,
                index: actualIndex,
                top:
                    itemOffsets[actualIndex] ??
                    actualIndex * estimatedItemHeight,
            };
        }),
    );

    function handleScroll(event) {
        scrollTop = event.target.scrollTop;
        onscroll(event);
    }

    function updateContainerHeight() {
        if (scrollContainer) {
            containerHeight = scrollContainer.clientHeight;
        }
    }

    function measureItem(element, index) {
        if (!element) return { destroy: () => {} };

        const updateHeight = () => {
            const height = element.offsetHeight;
            if (height > 0 && itemHeights.get(index) !== height) {
                itemHeights.set(index, height);
                itemHeights = new Map(itemHeights);
            }
        };

        updateHeight();

        const resizeObserver = new ResizeObserver(updateHeight);
        resizeObserver.observe(element);

        return {
            destroy() {
                resizeObserver.disconnect();
            },
        };
    }

    export function scrollToIndex(index, options = {}) {
        if (scrollContainer && index >= 0 && index < items.length) {
            const targetTop = itemOffsets[index] || index * estimatedItemHeight;
            scrollContainer.scrollTo({
                top: targetTop,
                behavior: options.behavior || "auto",
            });
        }
    }

    export function getVisibleRange() {
        return visibleRange;
    }

    $effect(() => {
        if (!scrollContainer) return;

        mounted = true;
        updateContainerHeight();

        const resizeObserver = new ResizeObserver(updateContainerHeight);
        resizeObserver.observe(scrollContainer);

        return () => {
            resizeObserver.disconnect();
        };
    });
</script>

<div
    bind:this={scrollContainer}
    onscroll={handleScroll}
    class="virtual-list-container {className}"
    style="height: {height}; overflow-y: auto; -webkit-overflow-scrolling: touch;"
>
    <div
        class="virtual-list-inner"
        style="height: {totalHeight}px; position: relative;"
    >
        {#each visibleItems as { item, index, top } (index)}
            <div
                class="virtual-list-item"
                style="position: absolute; top: {top}px; width: 100%; left: 0;"
                data-index={index}
                use:measureItem={index}
            >
                {#if children}
                    {@render children(item, index)}
                {:else}
                    <div class="p-4 border-b">
                        Item {index}: {JSON.stringify(item)}
                    </div>
                {/if}
            </div>
        {/each}
    </div>
</div>

<style>
    .virtual-list-container {
        position: relative;
        -webkit-overflow-scrolling: touch;
        will-change: scroll-position;
    }

    .virtual-list-inner {
        position: relative;
        contain: layout;
    }

    .virtual-list-item {
        position: absolute;
        width: 100%;
        left: 0;
        box-sizing: border-box;
        contain: layout style;
    }
</style>
