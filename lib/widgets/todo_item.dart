import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/todo.dart';
import '../constants/colors.dart';

class ToDoItem extends StatelessWidget {
  final ToDo todo;
  final Function onToDoChanged;
  final Function onDeleteItem;

  Color _getDeadlineColor() {
    if (todo.isDone) {
      return Colors.grey[200]!; // Gray color when ticked off
    } else if (todo.completionDate != null && todo.completionTime != null) {
      DateTime currentDate = DateTime.now();
      DateTime deadline = DateTime(
        todo.completionDate!.year,
        todo.completionDate!.month,
        todo.completionDate!.day,
        todo.completionTime!.hour,
        todo.completionTime!.minute,
      );
      return currentDate.isBefore(deadline) ? Colors.green : Colors.red;
    }
    return Colors.grey[200]!; // Default color if no deadline is set
  }

  const ToDoItem({
    Key? key,
    required this.todo,
    required this.onToDoChanged,
    required this.onDeleteItem
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          onToDoChanged(todo);
        },
        child: Row(
          children: [
            Icon(
              todo.isDone ? Icons.check_box : Icons.check_box_outline_blank,
              color: tdBlue,
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      todo.todoText!,
                      style: TextStyle(
                        fontSize: 16,
                        color: tdBlack,
                        decoration: todo.isDone ? TextDecoration.lineThrough : null,
                      ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: _getDeadlineColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                        '${todo.completionDate != null ? DateFormat('yyyy-MM-dd').format(todo.completionDate!) : ''} ${todo.completionTime != null ? todo.completionTime!.format(context) : ''}',
                        style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                padding: EdgeInsets.all(0),
                color: Colors.white, // Keep the bin icon white
                iconSize: 18,
                icon: Icon(Icons.delete),
                onPressed: () {
                  onDeleteItem(todo.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
