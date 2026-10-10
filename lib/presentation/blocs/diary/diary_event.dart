import 'package:equatable/equatable.dart';

abstract class DiaryEvent extends Equatable {
  const DiaryEvent();

  @override
  List<Object?> get props => [];
}

class LoadDiaryEntries extends DiaryEvent {
  const LoadDiaryEntries();
}

class AddMortalityEntry extends DiaryEvent {
  final int deaths;
  final String notes;

  const AddMortalityEntry(this.deaths, this.notes);

  @override
  List<Object?> get props => [deaths, notes];
}

class AddFeedEntry extends DiaryEvent {
  final double kg;
  final String notes;

  const AddFeedEntry(this.kg, this.notes);

  @override
  List<Object?> get props => [kg, notes];
}

class AddWeightEntry extends DiaryEvent {
  final double grams;
  final String notes;

  const AddWeightEntry(this.grams, this.notes);

  @override
  List<Object?> get props => [grams, notes];
}
