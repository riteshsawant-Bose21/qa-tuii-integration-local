import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'message_state.dart';

/// ViewModel/Cubit for the Message tab panel.
///
/// Manages message player selections and individual message selections.
/// Loads and persists data using [ProjectViewModel] relationships.
class MessageViewModel extends Cubit<MessageState> {
  MessageViewModel() : super(const MessageInitial());

  /// Lazy reference to ProjectViewModel.
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  /// Get current loaded state, or null if not loaded.
  MessageLoaded? get _loaded {
    final MessageState s = state;
    return s is MessageLoaded ? s : null;
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  /// Loads message data for the specified controller.
  void loadData(String controllerId) {
    emit(const MessageLoading());

    try {
      // Load all message players from project
      final List<Source> messagePlayers =
          _projectViewModel.sources
              .where(
                (Source s) =>
                    s.type == SourceType.paging &&
                    (s.pagingSourceType == PagingSourceType.messagePlayer || s.pagingSourceType == PagingSourceType.messagePlayerWithZoneSelect),
              )
              .toList();

      // Load messages for each player
      final Map<String, List<MessageModel>> messagesPerPlayer = <String, List<MessageModel>>{
        for (final Source s in messagePlayers) s.id: _projectViewModel.getMessagesForSource(s.id),
      };

      // Load persisted selections from relationships
      final List<ControllerPageModel> controllerPages = _projectViewModel.getControllerPages(controllerId);

      final Set<String> selectedMessagePlayerIds = <String>{};
      final Map<String, Set<String>> selectedMessageIdsPerPlayer = <String, Set<String>>{};

      for (final ControllerPageModel page in controllerPages.where((ControllerPageModel p) => p.type == ControllerPageType.message)) {
        selectedMessagePlayerIds.add(page.id);
        selectedMessageIdsPerPlayer[page.id] = _projectViewModel.getMessageIdsForPage(page.id);
      }

      // Determine active page
      final String? selectedMessagePageId = selectedMessagePlayerIds.isNotEmpty ? selectedMessagePlayerIds.last : null;

      emit(
        MessageLoaded(
          messagePlayers: messagePlayers,
          messagesPerPlayer: messagesPerPlayer,
          selectedMessagePlayerIds: selectedMessagePlayerIds,
          selectedMessagePageId: selectedMessagePageId,
          selectedMessageIdsPerPlayer: selectedMessageIdsPerPlayer,
          controllerId: controllerId,
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'MessageViewModel: failed to load data: $e');
      emit(MessageError(message: 'Failed to load message data: $e'));
    }
  }

  /// Reloads data preserving in-memory selections if available.
  void refresh() {
    final MessageLoaded? loaded = _loaded;
    if (loaded?.controllerId != null) {
      _reloadWithPreservation(loaded!.controllerId!);
    }
  }

  void _reloadWithPreservation(String controllerId) {
    final MessageLoaded? current = _loaded;

    try {
      // Load all message players from project
      final List<Source> messagePlayers =
          _projectViewModel.sources
              .where(
                (Source s) =>
                    s.type == SourceType.paging &&
                    (s.pagingSourceType == PagingSourceType.messagePlayer || s.pagingSourceType == PagingSourceType.messagePlayerWithZoneSelect),
              )
              .toList();

      // Load messages for each player
      final Map<String, List<MessageModel>> messagesPerPlayer = <String, List<MessageModel>>{
        for (final Source s in messagePlayers) s.id: _projectViewModel.getMessagesForSource(s.id),
      };

      // Preserve in-memory selections if they exist
      final bool useInMemory = current != null && current.selectedMessageIdsPerPlayer.isNotEmpty;

      Set<String> selectedMessagePlayerIds;
      Map<String, Set<String>> selectedMessageIdsPerPlayer;
      String? selectedMessagePageId;

      if (useInMemory) {
        selectedMessagePlayerIds = current.selectedMessagePlayerIds;
        selectedMessageIdsPerPlayer = current.selectedMessageIdsPerPlayer;
        selectedMessagePageId = current.selectedMessagePageId;
      } else {
        // Load from persistence
        final List<ControllerPageModel> controllerPages = _projectViewModel.getControllerPages(controllerId);

        selectedMessagePlayerIds = <String>{};
        selectedMessageIdsPerPlayer = <String, Set<String>>{};

        for (final ControllerPageModel page in controllerPages.where((ControllerPageModel p) => p.type == ControllerPageType.message)) {
          selectedMessagePlayerIds.add(page.id);
          selectedMessageIdsPerPlayer[page.id] = _projectViewModel.getMessageIdsForPage(page.id);
        }

        selectedMessagePageId = selectedMessagePlayerIds.isNotEmpty ? selectedMessagePlayerIds.last : null;
      }

      emit(
        MessageLoaded(
          messagePlayers: messagePlayers,
          messagesPerPlayer: messagesPerPlayer,
          selectedMessagePlayerIds: selectedMessagePlayerIds,
          selectedMessagePageId: selectedMessagePageId,
          selectedMessageIdsPerPlayer: selectedMessageIdsPerPlayer,
          controllerId: controllerId,
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'MessageViewModel: failed to refresh: $e');
    }
  }

  // ─── Message Player Actions ────────────────────────────────────────────────

  /// Toggle message-player checkbox.
  /// Checking ON  → adds a page and makes it active.
  /// Checking OFF → removes the page; last remaining becomes active.
  void toggleMessagePlayerSelection(String playerId) {
    final MessageLoaded? loaded = _loaded;
    if (loaded == null) return;

    final bool wasChecked = loaded.selectedMessagePlayerIds.contains(playerId);
    final Set<String> updated = Set<String>.from(loaded.selectedMessagePlayerIds);

    if (wasChecked) {
      updated.remove(playerId);
    } else {
      updated.add(playerId);
    }

    String? newPageId;
    if (!wasChecked) {
      newPageId = playerId;
    } else if (loaded.selectedMessagePageId == playerId) {
      newPageId = updated.isNotEmpty ? updated.last : null;
    } else {
      newPageId = loaded.selectedMessagePageId;
    }

    // Persist
    if (loaded.controllerId != null) {
      _persistMessagePages(
        controllerId: loaded.controllerId!,
        selectedPlayerIds: updated,
        selectedMessageIdsPerPlayer: loaded.selectedMessageIdsPerPlayer,
      );
    }

    emit(
      loaded.copyWith(
        selectedMessagePlayerIds: updated,
        selectedMessagePageId: newPageId,
      ),
    );
  }

  /// Select a message-player page (highlights it in the PAGES panel).
  void selectMessagePage(String playerId) {
    final MessageLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(selectedMessagePageId: playerId));
  }

  // ─── Individual Message Actions ────────────────────────────────────────────

  /// Toggle individual message checkbox for a given player.
  void toggleMessageSelection(String playerId, String messageId) {
    final MessageLoaded? loaded = _loaded;
    if (loaded == null) return;

    final Map<String, Set<String>> updatedMap = <String, Set<String>>{
      for (final MapEntry<String, Set<String>> e in loaded.selectedMessageIdsPerPlayer.entries) e.key: Set<String>.from(e.value),
    };

    final Set<String> playerSet = Set<String>.from(updatedMap[playerId] ?? <String>{});
    if (playerSet.contains(messageId)) {
      playerSet.remove(messageId);
    } else {
      playerSet.add(messageId);
    }
    updatedMap[playerId] = playerSet;

    // Persist
    if (loaded.controllerId != null) {
      _persistMessagePages(
        controllerId: loaded.controllerId!,
        selectedPlayerIds: loaded.selectedMessagePlayerIds,
        selectedMessageIdsPerPlayer: updatedMap,
      );
    }

    emit(loaded.copyWith(selectedMessageIdsPerPlayer: updatedMap));
  }

  // ─── Persistence ───────────────────────────────────────────────────────────

  /// Persists message-player pages and their selected messages.
  void _persistMessagePages({
    required String controllerId,
    required Set<String> selectedPlayerIds,
    required Map<String, Set<String>> selectedMessageIdsPerPlayer,
  }) {
    final List<ControllerPageModel> newMessagePages = <ControllerPageModel>[
      for (final String sourceId in selectedPlayerIds) ControllerPageModel(id: sourceId, type: ControllerPageType.message, name: ''),
    ];

    // Preserve existing non-message pages
    final List<ControllerPageModel> existingOtherPages =
        _projectViewModel.getControllerPages(controllerId).where((ControllerPageModel p) => p.type != ControllerPageType.message).toList();

    _projectViewModel.setControllerPages(
      controllerId: controllerId,
      pages: <ControllerPageModel>[...existingOtherPages, ...newMessagePages],
    );

    // Update message ID relationships for each player
    for (final String sourceId in selectedPlayerIds) {
      _projectViewModel.setMessageIdsForPage(
        pageId: sourceId,
        messageIds: selectedMessageIdsPerPlayer[sourceId] ?? <String>{},
      );
    }
  }
}
