import SwiftUI
import UserNotifications

struct ContentView: View {

    @State private var tasks = [Task]()
    @State private var newTaskTitle = ""
    @State private var isEditing = false
    @State private var editingTask: Task?
    @State private var taskDueDate = Date().addingTimeInterval(3600 * 24)
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    private func scheduleNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "TASK_CATEGORY"
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.taskDueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let storedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = storedTasks
        }
    }
    
    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "tasks")
        }
    }
    
    private func addTask() {
        let newTask = Task(title: newTaskTitle, isCompleted: false, taskDueDate: taskDueDate)
        tasks.append(newTask)
        saveTasks()
        newTaskTitle = ""
        scheduleNotification(for: newTask)
    }
    
    private func toggleTaskCompletion(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        saveTasks()
    }
    
    private func clearAllTasks() {
        tasks.removeAll()
        saveTasks()
    }
    
    private func startEditing(task: Task) {
        editingTask = task
        newTaskTitle = task.title
        taskDueDate = task.taskDueDate
        isEditing = true
    }
    
    private func updateTask() {
        if let task = editingTask,
           let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].title = newTaskTitle
            tasks[index].taskDueDate = taskDueDate
            saveTasks()
            isEditing = false
            newTaskTitle = ""
            editingTask = nil
        }
    }
    
    private func cancelEditing() {
        isEditing = false
        newTaskTitle = ""
        editingTask = nil
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    TextField(isEditing ? "Edit task..." : "Enter a new task...", text: $newTaskTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: isEditing ? updateTask : addTask) {
                        Image(systemName: isEditing ? "pencil.circle.fill":"paperplane.circle.fill")

                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                HStack {
                    DatePicker(
                        "Due by",
                        selection: $taskDueDate,
                        displayedComponents: [.hourAndMinute, .date]
                    )
                    .disabled(newTaskTitle.isEmpty)
                }
                .padding()
                List {
                    ForEach(tasks) { task in
                        HStack {
                            Button(action: {
                                toggleTaskCompletion(task: task)
                            }) {
                                Image(systemName: task.isCompleted ? "checkmark.square" : "square")
                            }
                            Text(task.title)
                                .strikethrough(task.isCompleted, color: .red)
                                .onTapGesture {
                                    toggleTaskCompletion(task: task)
                                }
                                .onLongPressGesture {
                                    startEditing(task: task)
                                }
                            if isEditing && editingTask?.id == task.id {
                                DatePicker(
                                    "",
                                    selection: $taskDueDate,
                                    displayedComponents: [.hourAndMinute, .date]
                                )
                            } else {
                                Text("\(task.taskDueDate, formatter: dateFormatter)")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                    }
                    .onDelete(perform: deleteTask)
                }

            }
            .onAppear(perform: loadTasks)
            .navigationTitle("Task Tracker")
            .navigationBarItems(leading: isEditing ? Button(action: cancelEditing) {
                Text("Cancel")
            } : nil, trailing: Button(action: clearAllTasks) {
                Text("Clear All")
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    public static var previews: some View {
        ContentView()
    }
}
