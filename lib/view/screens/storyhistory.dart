import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:spokiai/model/commonresponse.dart';
import 'package:spokiai/model/storyhistory.dart';
import 'package:spokiai/view/screens/historyDescriptionscreen.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import 'package:spokiai/viewmodel/cubit/appcubit.dart';

class StoryHistoryScreen extends StatefulWidget {
  const StoryHistoryScreen({super.key});

  @override
  State<StoryHistoryScreen> createState() => _StoryHistoryScreenState();
}

class _StoryHistoryScreenState extends State<StoryHistoryScreen> {
  String token = "";
  List<StoryList> storyList = [];
  int selectedIndex = -1;

  @override
  void initState() {
    token = PreferenceManager.getStringValue(key: "token") ?? "";
    BlocProvider.of<AppCubit>(context).storyHistory(token);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        title: const Text("Story History"),
        backgroundColor: surfaceBg,
      ),
      body: BlocConsumer<AppCubit, AppStates>(
        listener: (context, state) {
          if (state.status == AppStatus.storyHistorySuccess) {
            StoryHistoryResponse storyHistoryResponse =
                state.responseData?.response as StoryHistoryResponse;
            storyList.clear();
            if (storyHistoryResponse.data?.length != 0) {
              storyList.addAll(storyHistoryResponse.data ?? []);
            }
          }

          if (state.status == AppStatus.deleteStorySuccess) {
            CommonResponse commonResponse =
                state.responseData?.response as CommonResponse;
            showToast(
                context: context,
                message: commonResponse.message.toString(),
                buttonColor: successColor);
            setState(() {
              if (selectedIndex >= 0 && selectedIndex < storyList.length) {
                storyList.removeAt(selectedIndex);
              }
            });
          }

          if (state.status == AppStatus.storyHistoryError ||
              state.status == AppStatus.deleteStoryError) {
            showToast(
                context: context,
                message: state.errorData?.message.toString() ?? "");
          }
        },
        builder: (context, state) {
          if (state.status == AppStatus.storyHistoryLoading) {
            return Center(
              child: CircularProgressIndicator(color: appColor),
            );
          }
          if (storyList.isEmpty) {
            return _emptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: storyList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = storyList[index];
              final createdAt = item.createdAt?.toString() ?? "";
              DateTime? localTime;
              try {
                localTime = DateTime.parse(createdAt).toLocal();
              } catch (_) {}
              final formattedDate = localTime != null
                  ? DateFormat("d MMM yyyy").format(localTime)
                  : "";
              final formattedTime = localTime != null
                  ? DateFormat("hh:mm a").format(localTime)
                  : "";

              return SectionCard(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryDescription(
                            id: item.id?.toString() ?? ""),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: brandGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.metadata?.title?.toString() ?? "Story",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _deleteButton(state, index),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.story?.toString() ?? "",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Divider(color: surfaceMuted, thickness: 1, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _metaChip(
                              Icons.calendar_today_rounded, formattedDate),
                          _metaChip(Icons.schedule_rounded, formattedTime),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _deleteButton(AppStates state, int index) {
    final loading = state.status == AppStatus.deleteStoryLoading &&
        selectedIndex == index;
    return IconButton(
      splashRadius: 20,
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: errorColor,
              ),
            )
          : Icon(Icons.delete_outline_rounded, color: errorColor),
      onPressed: () async {
        final bool? isConfirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text("Delete Story"),
            content: const Text("Are you sure you want to delete this story?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete",
                    style: TextStyle(color: errorColor)),
              ),
            ],
          ),
        );

        if (isConfirm == true) {
          setState(() => selectedIndex = index);
          BlocProvider.of<AppCubit>(context).deleteStory(
            token,
            storyList[index].id?.toString() ?? "",
          );
        }
      },
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 42,
                color: appColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "No stories yet",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Create your first story from the home tab — it will show up here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
