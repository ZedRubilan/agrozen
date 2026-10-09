import 'package:equatable/equatable.dart';
abstract class DiaryEvent extends Equatable {
  const DiaryEvent();
  @override
  List<Object> get props => [];
}
class LoadDiaryEntries extends DiaryEvent {}
class AddMortalityEntry extends DiaryEvent {
  final int deaths;
  final String notes;
  const AddMortalityEntry(this.deaths, this.notes);
}
class AddFeedEntry extends DiaryEvent {
  final double kg;
  final String notes;
  const AddFeedEntry(this.kg, this.notes);
}
class AddWeightEntry extends DiaryEvent {
  final double grams;
  final String notes;
  const AddWeightEntry(this.grams, this.notes);
}
