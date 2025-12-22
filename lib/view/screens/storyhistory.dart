import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    print(token);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "History",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<AppCubit, AppStates>(
        listener: (context, state) {
          if (state.status == AppStatus.storyHistorySuccess) {
            StoryHistoryResponse storyHistoryResponse =
                state.responseData?.response as StoryHistoryResponse;
            if (storyHistoryResponse.data?.length != 0) {
              storyList.addAll(storyHistoryResponse.data ?? []);
            }
          }

          if (state.status == AppStatus.deleteStorySuccess) {
            CommonResponse commonResponse =
                state.responseData?.response as CommonResponse;

            showToast(
                context: context,
                message: commonResponse.message.toString() ?? "");
            setState(() {
              storyList.removeAt(selectedIndex);
            });
          }

          if (state.status == AppStatus.storyHistoryError &&
              state.status == AppStatus.deleteStoryError) {
            showToast(
                context: context,
                message: state.errorData?.message.toString() ?? "");
          }
        },
        builder: (context, state) {
          if (state.status == AppStatus.storyHistoryLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: appColor,
              ),
            );
          }
          return storyList.isNotEmpty
              ? ListView.builder(
                  itemCount: storyList.length,
                  itemBuilder: (context, index) {
                    String createdAt =
                        storyList[index].createdAt.toString() ?? "";

                    DateTime localTime = DateTime.parse(createdAt).toLocal();

                    String formattedDate =
                        DateFormat("d MMM yyyy").format(localTime);

                    String formattedTime =
                        DateFormat("hh:mm a").format(localTime);

                    print(formattedTime);

                    print(formattedDate);
                    return Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) {
                              return HistoryDescription(
                                  id: storyList[index].id.toString() ?? "");
                            },
                          ));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.4),
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.access_time_filled_sharp,
                                        color: appColor,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.68,
                                        child: textRoboto(
                                            text: storyList[index]
                                                    .metadata
                                                    ?.title
                                                    .toString() ??
                                                "",
                                            fontSize: 15,
                                            textAlign: TextAlign.start,
                                            maxLines: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final bool? isConfirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text("Delete Story"),
                                              content: const Text("Are you sure you want to delete this story?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text(
                                                    "Delete",
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (isConfirm == true) {
                                            setState(() {
                                              selectedIndex = index;
                                            });

                                            BlocProvider.of<AppCubit>(context).deleteStory(
                                              token,
                                              storyList[index].id?.toString() ?? "",
                                            );
                                          }
                                        },
                                        child: state.status == AppStatus.deleteStoryLoading &&
                                            selectedIndex == index
                                            ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                            : const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: textRoboto(
                                      fontSize: 15,
                                      textAlign: TextAlign.start,
                                      text: storyList[index].story.toString() ??
                                          "",
                                      maxLines: 3),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, right: 8),
                                  child: Divider(
                                    color: Colors.grey.withOpacity(0.4),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      textRoboto(text: formattedDate),
                                      textRoboto(text: formattedTime)
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: textRoboto(text: "No history found"),
                );
        },
      ),
    );
  }
}
